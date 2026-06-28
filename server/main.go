package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"log/slog"
	"net/http"
	"os"
	"time"

	_ "github.com/tursodatabase/libsql-client-go/libsql"
)

// set this via -ldflags "-X main.version=test"
var version = "dev"

type config struct {
	port    string
	dbUrl   string
	dbToken string
}

type score struct {
	Id        int    `json:"id"`
	Score     int    `json:"score"`
	Name      string `json:"name"`
	Timestamp int64  `json:"timestamp"`
	Time      string `json:"time"`
	Version   string `json:"version"`
}

func main() {

	slog.Info("Starting application", "version", version)

	config := config{
		port:    "8080",
		dbUrl:   os.Getenv("DB_URL"),
		dbToken: os.Getenv("DB_TOKEN"),
	}

	slog.SetLogLoggerLevel(slog.LevelDebug)

	slog.Info("Connecting to database", "url", config.dbUrl)

	url := fmt.Sprintf("%s?authToken=%s", config.dbUrl, config.dbToken)
	db, err := sql.Open("libsql", url)
	if err != nil {
		log.Fatalf("open database %s: %v", config.dbUrl, err)
	}
	defer db.Close()

	mux := http.NewServeMux()
	mux.HandleFunc("GET /api/v1/score", getScore(db))
	mux.HandleFunc("POST /api/v1/score", addScore(db))

	slog.Info("listening", "port", config.port)
	if err := http.ListenAndServe(fmt.Sprintf(":%s", config.port), mux); err != nil {
		log.Fatalf("server: %v", err)
	}
}

func getScore(db *sql.DB) http.HandlerFunc {
	slog.Debug("Post Score")
	return func(w http.ResponseWriter, r *http.Request) {
		slog.Debug("Get Score")

		scores, err := getScoresFromDB(db)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(scores)
		slog.Debug(fmt.Sprintf("%v", scores))
	}
}

func getScoresFromDB(db *sql.DB) ([]score, error) {
	// TODO: Add version filter as param
	rows, err := db.Query(`
		SELECT id, MAX(score), name, timestamp, time, version 
		FROM score 
		GROUP BY name
		ORDER BY MAX(score) DESC
		LIMIT 5
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	scores := []score{}
	for rows.Next() {
		var s score
		if err := rows.Scan(&s.Id, &s.Score, &s.Name, &s.Timestamp, &s.Time, &s.Version); err != nil {
			return nil, err
		}
		scores = append(scores, s)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	return scores, nil
}

func addScore(db *sql.DB) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var score score
		if err := json.NewDecoder(r.Body).Decode(&score); err != nil {
			http.Error(w, "invalid request body", http.StatusBadRequest)
			return
		}

		err := insertScore(db, score)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}

		scores, err := getScoresFromDB(db)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(scores)
	}
}

func insertScore(db *sql.DB, score score) error {
	rows, err := db.Exec("INSERT INTO score (score, name, timestamp, time, version) VALUES (?, ?, ?, ?, ?)", score.Score, score.Name, time.Now().Unix(), score.Time, score.Version)
	if err != nil {
		return err
	}

	effected, err := rows.RowsAffected()
	if err != nil {
		return err
	}

	lastId, err := rows.LastInsertId()
	if err != nil {
		return err
	}

	slog.Debug("Inserted", "row effected", effected, "id", lastId)
	return nil
}
