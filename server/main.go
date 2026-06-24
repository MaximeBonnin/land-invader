package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"log/slog"
	"net/http"
	"os"

	_ "github.com/tursodatabase/libsql-client-go/libsql"
)

type config struct {
	port    string
	dbUrl   string
	dbToken string
}

type score struct {
	id        int
	score     int
	name      string
	timestamp int
	time      string
}

func main() {

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
	return func(w http.ResponseWriter, r *http.Request) {
		slog.Debug("Get Score")
		rows, err := db.Query("SELECT id, score, name, timestamp, time FROM score")
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		defer rows.Close()

		scores := []score{}
		for rows.Next() {
			var s score
			if err := rows.Scan(&s.id, &s.score, &s.name, &s.timestamp, &s.time); err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			scores = append(scores, s)
		}
		if err := rows.Err(); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(scores)
		slog.Debug(fmt.Sprintf("%s", scores))
	}
}

func addScore(db *sql.DB) http.HandlerFunc {
	// FIXME this is broken
	score := score{}
	return func(w http.ResponseWriter, r *http.Request) {
		rows, err := db.Exec("INSERT INTO score (score, name, timestamp, time) VALUES (?, ?, ?, ?)", score.score, score.name, score.timestamp, score.time)
		if err != nil {
			slog.Error(err.Error())
			http.Error(w, err.Error(), 500)
		}
		log.Default().Println(rows)
	}
}
