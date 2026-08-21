package httpapi

import (
	"carecontinuity/internal/prevention"
	"encoding/json"
	"errors"
	"github.com/go-chi/chi/v5"
	"net/http"
)

func (s *Server) preventionToken(r *http.Request) string {
	token := r.Header.Get("Authorization")
	if len(token) >= 7 && token[:7] == "Bearer " {
		return token[7:]
	}
	return token
}
func (s *Server) preventionError(w http.ResponseWriter, err error) {
	status := http.StatusBadRequest
	if errors.Is(err, prevention.ErrNotFound) {
		status = http.StatusNotFound
	}
	if err.Error() == "forbidden" {
		status = http.StatusForbidden
	}
	http.Error(w, `{"code":"prevention_request_failed","message":"`+err.Error()+`"}`, status)
}
func (s *Server) CreatePreventionStation(w http.ResponseWriter, r *http.Request) {
	var v prevention.Station
	if json.NewDecoder(r.Body).Decode(&v) != nil {
		http.Error(w, "invalid JSON", 400)
		return
	}
	out, err := s.preventionSvc.CreateStation(r.Context(), s.preventionToken(r), v)
	if err != nil {
		s.preventionError(w, err)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(out)
}
func (s *Server) ListPreventionStations(w http.ResponseWriter, r *http.Request) {
	items, total, err := s.store.ListStations(r.Context(), 20, 0)
	if err != nil {
		s.preventionError(w, err)
		return
	}
	_ = json.NewEncoder(w).Encode(map[string]any{"items": items, "total": total})
}
func (s *Server) ReportPreventionHazard(w http.ResponseWriter, r *http.Request) {
	var v prevention.Hazard
	if json.NewDecoder(r.Body).Decode(&v) != nil {
		http.Error(w, "invalid JSON", 400)
		return
	}
	out, err := s.preventionSvc.ReportHazard(r.Context(), s.preventionToken(r), v)
	if err != nil {
		s.preventionError(w, err)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(out)
}
func (s *Server) AssignPreventionHazard(w http.ResponseWriter, r *http.Request) {
	var v struct {
		OperatorID string `json:"operator_id"`
	}
	_ = json.NewDecoder(r.Body).Decode(&v)
	err := s.preventionSvc.AssignHazard(r.Context(), s.preventionToken(r), chi.URLParam(r, "id"), v.OperatorID)
	if err != nil {
		s.preventionError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
func (s *Server) RectifyPreventionHazard(w http.ResponseWriter, r *http.Request) {
	var v struct {
		Evidence string `json:"evidence"`
	}
	_ = json.NewDecoder(r.Body).Decode(&v)
	err := s.preventionSvc.RectifyHazard(r.Context(), s.preventionToken(r), chi.URLParam(r, "id"), v.Evidence)
	if err != nil {
		s.preventionError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
func (s *Server) VerifyPreventionHazard(w http.ResponseWriter, r *http.Request) {
	var v struct {
		Evidence string `json:"evidence"`
	}
	_ = json.NewDecoder(r.Body).Decode(&v)
	err := s.preventionSvc.VerifyHazard(r.Context(), s.preventionToken(r), chi.URLParam(r, "id"), v.Evidence)
	if err != nil {
		s.preventionError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
