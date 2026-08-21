FROM golang:1.26 AS builder
ENV GOTOOLCHAIN=local
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /carecontinuity ./cmd/carecontinuity
RUN CGO_ENABLED=0 go build -o /carecontinuityctl ./cmd/carecontinuityctl

FROM golang:1.26
COPY --from=builder /carecontinuity /carecontinuity
COPY --from=builder /carecontinuityctl /carecontinuityctl
EXPOSE 56058
ENTRYPOINT ["/carecontinuity"]
