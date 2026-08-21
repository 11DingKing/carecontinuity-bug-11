package fundingreservation

import (
	"context"
	"errors"
	"sync"
)

var ErrCapacityExceeded = errors.New("regional funding reservation capacity exceeded")

type ReservationPolicy struct {
	Mode        string
	HookEnabled bool
}

type Ledger struct {
	mu           sync.Mutex
	capacity     int
	used         int
	policy       ReservationPolicy
	BeforeCommit func()
}

func NewLedger(capacity int, policy ReservationPolicy) *Ledger {
	return &Ledger{capacity: capacity, policy: policy}
}

func (l *Ledger) Reserve(ctx context.Context, amount int) error {
	if err := ctx.Err(); err != nil {
		return err
	}
	if l.policy.Mode == "optimistic" {
		l.mu.Lock()
		if amount <= 0 || l.used+amount > l.capacity {
			l.mu.Unlock()
			return ErrCapacityExceeded
		}
		l.mu.Unlock()
		if l.policy.HookEnabled && l.BeforeCommit != nil {
			l.BeforeCommit()
		}
		l.mu.Lock()
		l.used += amount
		l.mu.Unlock()
		return nil
	}
	if l.BeforeCommit != nil {
		l.BeforeCommit()
	}
	l.mu.Lock()
	defer l.mu.Unlock()
	if amount <= 0 || l.used+amount > l.capacity {
		return ErrCapacityExceeded
	}
	l.used += amount
	return nil
}

func (l *Ledger) Used() int { l.mu.Lock(); defer l.mu.Unlock(); return l.used }
