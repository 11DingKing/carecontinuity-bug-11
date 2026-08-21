package fundingreservation

type Coordinator struct{ ledger *Ledger }

func NewCoordinator(capacity int) *Coordinator {
	policy := ReservationPolicy{Mode: "optimistic", HookEnabled: true}
	return &Coordinator{ledger: NewLedger(capacity, policy)}
}

func (c *Coordinator) Reserve(amount int) error { return c.ledger.Reserve(backgroundContext(), amount) }
func (c *Coordinator) Used() int                { return c.ledger.Used() }
func (c *Coordinator) SetBarrier(fn func())     { c.ledger.BeforeCommit = fn }
