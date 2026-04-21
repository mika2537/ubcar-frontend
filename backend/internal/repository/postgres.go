package repository

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"cursorubcar/backend/internal/domain"
	"github.com/google/uuid"
	_ "github.com/lib/pq"
)

type PostgresRepository struct {
	db *sql.DB
}

func NewPostgresRepository(dsn string) (*PostgresRepository, error) {
	db, err := sql.Open("postgres", dsn)
	if err != nil {
		return nil, err
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := db.PingContext(ctx); err != nil {
		_ = db.Close()
		return nil, err
	}

	repo := &PostgresRepository{db: db}
	if err := repo.ensureSchema(ctx); err != nil {
		_ = db.Close()
		return nil, err
	}

	return repo, nil
}

func (r *PostgresRepository) Close() error {
	return r.db.Close()
}

func (r *PostgresRepository) ensureSchema(ctx context.Context) error {
	schema := `
	CREATE TABLE IF NOT EXISTS users (
		id TEXT PRIMARY KEY,
		name TEXT NOT NULL,
		email TEXT NOT NULL UNIQUE,
		password_hash TEXT NOT NULL,
		role TEXT NOT NULL,
		created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
	);

	CREATE TABLE IF NOT EXISTS saved_routes (
		id TEXT PRIMARY KEY,
		user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
		origin TEXT NOT NULL,
		destination TEXT NOT NULL,
		created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
	);
	`
	_, err := r.db.ExecContext(ctx, schema)
	return err
}

func (r *PostgresRepository) CreateUser(ctx context.Context, user domain.User) (domain.User, error) {
	if user.ID == "" {
		user.ID = uuid.NewString()
	}
	if user.CreatedAt.IsZero() {
		user.CreatedAt = time.Now().UTC()
	}

	query := `
	INSERT INTO users (id, name, email, password_hash, role, created_at)
	VALUES ($1, $2, $3, $4, $5, $6)
	RETURNING id, name, email, password_hash, role, created_at
	`

	var saved domain.User
	err := r.db.QueryRowContext(
		ctx,
		query,
		user.ID,
		user.Name,
		user.Email,
		user.PasswordHash,
		user.Role,
		user.CreatedAt,
	).Scan(
		&saved.ID,
		&saved.Name,
		&saved.Email,
		&saved.PasswordHash,
		&saved.Role,
		&saved.CreatedAt,
	)
	return saved, err
}

func (r *PostgresRepository) GetUserByEmail(ctx context.Context, email string) (domain.User, error) {
	query := `
	SELECT id, name, email, password_hash, role, created_at
	FROM users
	WHERE email = $1
	`

	var user domain.User
	err := r.db.QueryRowContext(ctx, query, email).Scan(
		&user.ID,
		&user.Name,
		&user.Email,
		&user.PasswordHash,
		&user.Role,
		&user.CreatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return domain.User{}, ErrNotFound
	}
	return user, err
}

func (r *PostgresRepository) GetUserByID(ctx context.Context, id string) (domain.User, error) {
	query := `
	SELECT id, name, email, password_hash, role, created_at
	FROM users
	WHERE id = $1
	`

	var user domain.User
	err := r.db.QueryRowContext(ctx, query, id).Scan(
		&user.ID,
		&user.Name,
		&user.Email,
		&user.PasswordHash,
		&user.Role,
		&user.CreatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return domain.User{}, ErrNotFound
	}
	return user, err
}

func (r *PostgresRepository) CreateSavedRoute(ctx context.Context, route domain.SavedRoute) (domain.SavedRoute, error) {
	if route.ID == "" {
		route.ID = uuid.NewString()
	}
	if route.CreatedAt.IsZero() {
		route.CreatedAt = time.Now().UTC()
	}

	query := `
	INSERT INTO saved_routes (id, user_id, origin, destination, created_at)
	VALUES ($1, $2, $3, $4, $5)
	RETURNING id, user_id, origin, destination, created_at
	`

	var saved domain.SavedRoute
	err := r.db.QueryRowContext(
		ctx,
		query,
		route.ID,
		route.UserID,
		route.From,
		route.To,
		route.CreatedAt,
	).Scan(
		&saved.ID,
		&saved.UserID,
		&saved.From,
		&saved.To,
		&saved.CreatedAt,
	)
	return saved, err
}

func (r *PostgresRepository) ListSavedRoutesByUser(ctx context.Context, userID string) ([]domain.SavedRoute, error) {
	query := `
	SELECT id, user_id, origin, destination, created_at
	FROM saved_routes
	WHERE user_id = $1
	ORDER BY created_at DESC
	`

	rows, err := r.db.QueryContext(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var routes []domain.SavedRoute
	for rows.Next() {
		var route domain.SavedRoute
		if err := rows.Scan(&route.ID, &route.UserID, &route.From, &route.To, &route.CreatedAt); err != nil {
			return nil, err
		}
		routes = append(routes, route)
	}
	return routes, rows.Err()
}
