package repository

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"cursorubcar/backend/internal/domain"
	"github.com/google/uuid"
	"github.com/lib/pq"
	_ "github.com/lib/pq"
)

type PostgresRepository struct {
	db    *sql.DB
	stmts map[string]*sql.Stmt
}

func NewPostgresRepository(dsn string) (*PostgresRepository, error) {
	db, err := sql.Open("postgres", dsn)
	if err != nil {
		return nil, err
	}
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(5 * time.Minute)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := db.PingContext(ctx); err != nil {
		_ = db.Close()
		return nil, err
	}

	repo := &PostgresRepository{
		db:    db,
		stmts: make(map[string]*sql.Stmt),
	}
	if err := repo.ensureSchema(ctx); err != nil {
		_ = db.Close()
		return nil, err
	}
	if err := repo.prepareQueries(ctx); err != nil {
		_ = repo.Close()
		return nil, err
	}

	return repo, nil
}

func (r *PostgresRepository) Close() error {
	for _, stmt := range r.stmts {
		_ = stmt.Close()
	}
	return r.db.Close()
}

func (r *PostgresRepository) prepareQueries(ctx context.Context) error {
	queries := map[string]string{
		"getUserByEmail": `
			SELECT id, name, email, password_hash, role, phone_number, gender, age, car_model, car_plate, driver_license_id, created_at
			FROM users
			WHERE email = $1
		`,
		"getUserByID": `
			SELECT id, name, email, password_hash, role, phone_number, gender, age, car_model, car_plate, driver_license_id, created_at
			FROM users
			WHERE id = $1
		`,
	}

	for name, query := range queries {
		stmt, err := r.db.PrepareContext(ctx, query)
		if err != nil {
			return err
		}
		r.stmts[name] = stmt
	}
	return nil
}

func (r *PostgresRepository) ensureSchema(ctx context.Context) error {
	schema := `
	CREATE TABLE IF NOT EXISTS users (
		id TEXT PRIMARY KEY,
		name TEXT NOT NULL,
		email TEXT NOT NULL UNIQUE,
		password_hash TEXT NOT NULL,
		role TEXT NOT NULL,
		phone_number TEXT NOT NULL DEFAULT '',
		gender TEXT NOT NULL DEFAULT '',
		age INTEGER NOT NULL DEFAULT 0,
		car_model TEXT NOT NULL DEFAULT '',
		car_plate TEXT NOT NULL DEFAULT '',
		driver_license_id TEXT NOT NULL DEFAULT '',
		created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
	);

	CREATE TABLE IF NOT EXISTS saved_routes (
		id TEXT PRIMARY KEY,
		user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
		origin TEXT NOT NULL,
		destination TEXT NOT NULL,
		midpoints TEXT[] NOT NULL DEFAULT '{}',
		created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
	);

	ALTER TABLE saved_routes
	ADD COLUMN IF NOT EXISTS midpoints TEXT[] NOT NULL DEFAULT '{}';

	ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_number TEXT NOT NULL DEFAULT '';
	ALTER TABLE users ADD COLUMN IF NOT EXISTS gender TEXT NOT NULL DEFAULT '';
	ALTER TABLE users ADD COLUMN IF NOT EXISTS age INTEGER NOT NULL DEFAULT 0;
	ALTER TABLE users ADD COLUMN IF NOT EXISTS car_model TEXT NOT NULL DEFAULT '';
	ALTER TABLE users ADD COLUMN IF NOT EXISTS car_plate TEXT NOT NULL DEFAULT '';
	ALTER TABLE users ADD COLUMN IF NOT EXISTS driver_license_id TEXT NOT NULL DEFAULT '';
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
	INSERT INTO users (
		id, name, email, password_hash, role,
		phone_number, gender, age, car_model, car_plate, driver_license_id,
		created_at
	)
	VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
	RETURNING id, name, email, password_hash, role, phone_number, gender, age, car_model, car_plate, driver_license_id, created_at
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
		user.PhoneNumber,
		user.Gender,
		user.Age,
		user.CarModel,
		user.CarPlate,
		user.DriverLicenseID,
		user.CreatedAt,
	).Scan(
		&saved.ID,
		&saved.Name,
		&saved.Email,
		&saved.PasswordHash,
		&saved.Role,
		&saved.PhoneNumber,
		&saved.Gender,
		&saved.Age,
		&saved.CarModel,
		&saved.CarPlate,
		&saved.DriverLicenseID,
		&saved.CreatedAt,
	)
	return saved, err
}

func (r *PostgresRepository) UpsertUser(ctx context.Context, user domain.User) (domain.User, error) {
	if user.ID == "" {
		user.ID = uuid.NewString()
	}
	if user.CreatedAt.IsZero() {
		user.CreatedAt = time.Now().UTC()
	}

	query := `
	INSERT INTO users (
		id, name, email, password_hash, role,
		phone_number, gender, age, car_model, car_plate, driver_license_id,
		created_at
	)
	VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
	ON CONFLICT (email) DO UPDATE SET
		name = EXCLUDED.name,
		password_hash = EXCLUDED.password_hash,
		role = EXCLUDED.role,
		phone_number = EXCLUDED.phone_number,
		gender = EXCLUDED.gender,
		age = EXCLUDED.age,
		car_model = EXCLUDED.car_model,
		car_plate = EXCLUDED.car_plate,
		driver_license_id = EXCLUDED.driver_license_id
	RETURNING id, name, email, password_hash, role, phone_number, gender, age, car_model, car_plate, driver_license_id, created_at
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
		user.PhoneNumber,
		user.Gender,
		user.Age,
		user.CarModel,
		user.CarPlate,
		user.DriverLicenseID,
		user.CreatedAt,
	).Scan(
		&saved.ID,
		&saved.Name,
		&saved.Email,
		&saved.PasswordHash,
		&saved.Role,
		&saved.PhoneNumber,
		&saved.Gender,
		&saved.Age,
		&saved.CarModel,
		&saved.CarPlate,
		&saved.DriverLicenseID,
		&saved.CreatedAt,
	)
	return saved, err
}

func (r *PostgresRepository) GetUserByEmail(ctx context.Context, email string) (domain.User, error) {
	var user domain.User
	err := r.stmts["getUserByEmail"].QueryRowContext(ctx, email).Scan(
		&user.ID,
		&user.Name,
		&user.Email,
		&user.PasswordHash,
		&user.Role,
		&user.PhoneNumber,
		&user.Gender,
		&user.Age,
		&user.CarModel,
		&user.CarPlate,
		&user.DriverLicenseID,
		&user.CreatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return domain.User{}, ErrNotFound
	}
	return user, err
}

func (r *PostgresRepository) GetUserByID(ctx context.Context, id string) (domain.User, error) {
	var user domain.User
	err := r.stmts["getUserByID"].QueryRowContext(ctx, id).Scan(
		&user.ID,
		&user.Name,
		&user.Email,
		&user.PasswordHash,
		&user.Role,
		&user.PhoneNumber,
		&user.Gender,
		&user.Age,
		&user.CarModel,
		&user.CarPlate,
		&user.DriverLicenseID,
		&user.CreatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return domain.User{}, ErrNotFound
	}
	return user, err
}

func (r *PostgresRepository) UpdateUserPasswordByEmail(ctx context.Context, email, passwordHash string) (bool, error) {
	query := `
	UPDATE users
	SET password_hash = $2
	WHERE email = $1
	`

	result, err := r.db.ExecContext(ctx, query, email, passwordHash)
	if err != nil {
		return false, err
	}

	updatedRows, err := result.RowsAffected()
	if err != nil {
		return false, err
	}

	return updatedRows > 0, nil
}

func (r *PostgresRepository) CreateSavedRoute(ctx context.Context, route domain.SavedRoute) (domain.SavedRoute, error) {
	if route.ID == "" {
		route.ID = uuid.NewString()
	}
	if route.CreatedAt.IsZero() {
		route.CreatedAt = time.Now().UTC()
	}
	if route.Midpoints == nil {
		route.Midpoints = []string{}
	}

	query := `
	INSERT INTO saved_routes (id, user_id, origin, destination, midpoints, created_at)
	VALUES ($1, $2, $3, $4, $5, $6)
	RETURNING id, user_id, origin, destination, midpoints, created_at
	`

	var saved domain.SavedRoute
	err := r.db.QueryRowContext(
		ctx,
		query,
		route.ID,
		route.UserID,
		route.From,
		route.To,
		pq.Array(route.Midpoints),
		route.CreatedAt,
	).Scan(
		&saved.ID,
		&saved.UserID,
		&saved.From,
		&saved.To,
		pq.Array(&saved.Midpoints),
		&saved.CreatedAt,
	)
	return saved, err
}

func (r *PostgresRepository) UpsertSavedRoute(ctx context.Context, route domain.SavedRoute) (domain.SavedRoute, error) {
	if route.ID == "" {
		route.ID = uuid.NewString()
	}
	if route.CreatedAt.IsZero() {
		route.CreatedAt = time.Now().UTC()
	}
	if route.Midpoints == nil {
		route.Midpoints = []string{}
	}

	query := `
	INSERT INTO saved_routes (id, user_id, origin, destination, midpoints, created_at)
	VALUES ($1, $2, $3, $4, $5, $6)
	ON CONFLICT (id) DO UPDATE SET
		user_id = EXCLUDED.user_id,
		origin = EXCLUDED.origin,
		destination = EXCLUDED.destination,
		midpoints = EXCLUDED.midpoints
	RETURNING id, user_id, origin, destination, midpoints, created_at
	`

	var saved domain.SavedRoute
	err := r.db.QueryRowContext(
		ctx,
		query,
		route.ID,
		route.UserID,
		route.From,
		route.To,
		pq.Array(route.Midpoints),
		route.CreatedAt,
	).Scan(
		&saved.ID,
		&saved.UserID,
		&saved.From,
		&saved.To,
		pq.Array(&saved.Midpoints),
		&saved.CreatedAt,
	)
	return saved, err
}

func (r *PostgresRepository) ListSavedRoutesByUser(ctx context.Context, userID string) ([]domain.SavedRoute, error) {
	query := `
	SELECT id, user_id, origin, destination, midpoints, created_at
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
		if err := rows.Scan(&route.ID, &route.UserID, &route.From, &route.To, pq.Array(&route.Midpoints), &route.CreatedAt); err != nil {
			return nil, err
		}
		routes = append(routes, route)
	}
	return routes, rows.Err()
}

func (r *PostgresRepository) ListAllSavedRoutes(ctx context.Context) ([]domain.SavedRoute, error) {
	query := `
	SELECT id, user_id, origin, destination, midpoints, created_at
	FROM saved_routes
	ORDER BY created_at DESC
	`

	rows, err := r.db.QueryContext(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var routes []domain.SavedRoute
	for rows.Next() {
		var route domain.SavedRoute
		if err := rows.Scan(&route.ID, &route.UserID, &route.From, &route.To, pq.Array(&route.Midpoints), &route.CreatedAt); err != nil {
			return nil, err
		}
		routes = append(routes, route)
	}
	return routes, rows.Err()
}
