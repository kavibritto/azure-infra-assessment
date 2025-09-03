package main

import (
	"context"
	"errors"
	"net/http"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"

	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

/* ----------------------------- Domain Models ----------------------------- */

type Item struct {
	ID          string    `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description,omitempty"`
	Price       float64   `json:"price"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

type CreateItemDTO struct {
	Name        string  `json:"name"`
	Description string  `json:"description"`
	Price       float64 `json:"price"`
}

type UpdateItemDTO struct {
	Name        *string  `json:"name"`
	Description *string  `json:"description"`
	Price       *float64 `json:"price"`
}

/* --------------------------- In-memory Repository ------------------------ */

type ItemRepo struct {
	mu    sync.RWMutex
	items map[string]Item
}

func NewItemRepo() *ItemRepo {
	return &ItemRepo{items: make(map[string]Item)}
}

func (r *ItemRepo) List() []Item {
	r.mu.RLock()
	defer r.mu.RUnlock()
	out := make([]Item, 0, len(r.items))
	for _, v := range r.items {
		out = append(out, v)
	}
	return out
}

func (r *ItemRepo) Get(id string) (Item, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	it, ok := r.items[id]
	return it, ok
}

func (r *ItemRepo) Create(in CreateItemDTO) (Item, error) {
	if in.Name == "" {
		return Item{}, errors.New("name is required")
	}
	if in.Price < 0 {
		return Item{}, errors.New("price must be >= 0")
	}
	now := time.Now().UTC()
	it := Item{
		ID:          uuid.NewString(),
		Name:        in.Name,
		Description: in.Description,
		Price:       in.Price,
		CreatedAt:   now,
		UpdatedAt:   now,
	}
	r.mu.Lock()
	defer r.mu.Unlock()
	r.items[it.ID] = it
	return it, nil
}

func (r *ItemRepo) Update(id string, in UpdateItemDTO) (Item, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	existing, ok := r.items[id]
	if !ok {
		return Item{}, echo.ErrNotFound
	}
	if in.Name != nil {
		if *in.Name == "" {
			return Item{}, errors.New("name cannot be empty")
		}
		existing.Name = *in.Name
	}
	if in.Description != nil {
		existing.Description = *in.Description
	}
	if in.Price != nil {
		if *in.Price < 0 {
			return Item{}, errors.New("price must be >= 0")
		}
		existing.Price = *in.Price
	}
	existing.UpdatedAt = time.Now().UTC()
	r.items[id] = existing
	return existing, nil
}

func (r *ItemRepo) Delete(id string) bool {
	r.mu.Lock()
	defer r.mu.Unlock()
	if _, ok := r.items[id]; !ok {
		return false
	}
	delete(r.items, id)
	return true
}

/* -------------------------------- Handlers ------------------------------- */

type Server struct {
	repo *ItemRepo
}

func NewServer() *Server {
	return &Server{repo: NewItemRepo()}
}

func (s *Server) Health(c echo.Context) error {
	return c.JSON(http.StatusOK, map[string]string{"status": "ok"})
}

func (s *Server) ListItems(c echo.Context) error {
	return c.JSON(http.StatusOK, s.repo.List())
}

func (s *Server) GetItem(c echo.Context) error {
	id := c.Param("id")
	if it, ok := s.repo.Get(id); ok {
		return c.JSON(http.StatusOK, it)
	}
	return echo.NewHTTPError(http.StatusNotFound, "item not found")
}

func (s *Server) CreateItem(c echo.Context) error {
	var dto CreateItemDTO
	if err := c.Bind(&dto); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "invalid JSON")
	}
	it, err := s.repo.Create(dto)
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, err.Error())
	}
	return c.JSON(http.StatusCreated, it)
}

func (s *Server) UpdateItem(c echo.Context) error {
	id := c.Param("id")
	var dto UpdateItemDTO
	if err := c.Bind(&dto); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "invalid JSON")
	}
	it, err := s.repo.Update(id, dto)
	if err != nil {
		if errors.Is(err, echo.ErrNotFound) {
			return echo.NewHTTPError(http.StatusNotFound, "item not found")
		}
		return echo.NewHTTPError(http.StatusBadRequest, err.Error())
	}
	return c.JSON(http.StatusOK, it)
}

func (s *Server) DeleteItem(c echo.Context) error {
	id := c.Param("id")
	if ok := s.repo.Delete(id); !ok {
		return echo.NewHTTPError(http.StatusNotFound, "item not found")
	}
	return c.NoContent(http.StatusNoContent)
}

/* --------------------------------- main ---------------------------------- */

func main() {
	e := echo.New()
	s := NewServer()

	// Middlewares
	e.Use(middleware.Recover())
	e.Use(middleware.RequestID())
	e.Use(middleware.Logger())
	e.Use(middleware.Secure())
	e.Use(middleware.CORS())

	// Routes
	e.GET("/healthz", s.Health)
	api := e.Group("/api")
	v1 := api.Group("/v1")
	items := v1.Group("/items")

	items.GET("", s.ListItems)         // GET /api/v1/items
	items.GET("/:id", s.GetItem)       // GET /api/v1/items/:id
	items.POST("", s.CreateItem)       // POST /api/v1/items
	items.PUT("/:id", s.UpdateItem)    // PUT /api/v1/items/:id
	items.DELETE("/:id", s.DeleteItem) // DELETE /api/v1/items/:id

	// Graceful shutdown
	go func() {
		if err := e.Start(":8080"); err != nil && !errors.Is(err, http.ErrServerClosed) {
			e.Logger.Fatal("shutting down the server: ", err)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM)
	<-quit

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := e.Shutdown(ctx); err != nil {
		e.Logger.Fatal(err)
	}
}
