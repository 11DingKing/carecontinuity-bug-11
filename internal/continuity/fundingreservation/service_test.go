package fundingreservation_test

import (
	"sync"
	"sync/atomic"
	"testing"

	"carecontinuity/internal/continuity/fundingreservation"
)

func TestRegionalFundingReservationPublicBehavior(t *testing.T) {
	coordinator := fundingreservation.NewCoordinator(100)
	release := make(chan struct{})
	var arrived atomic.Int32
	coordinator.SetBarrier(func() {
		if arrived.Add(1) == 2 {
			close(release)
		}
		<-release
	})
	var wg sync.WaitGroup
	errs := make(chan error, 2)
	for i := 0; i < 2; i++ {
		wg.Add(1)
		go func() { defer wg.Done(); errs <- coordinator.Reserve(60) }()
	}
	wg.Wait()
	close(errs)
	successes := 0
	for err := range errs {
		if err == nil {
			successes++
		}
	}
	if successes != 1 {
		t.Fatalf("expected one accepted reservation, got %d", successes)
	}
	if got := coordinator.Used(); got != 60 {
		t.Fatalf("expected used capacity 60, got %d", got)
	}
}
