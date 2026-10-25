package engine

import (
	"encoding/json"
	"strings"
	"testing"
)

func TestRedactorMasksUnknownQuotedCredentials(t *testing.T) {
	escaped, err := json.Marshal(map[string]string{"password": "fixture alpha \" beta", "token": "fixture gamma\\delta", "status": "running"})
	if err != nil {
		t.Fatal(err)
	}
	for name, line := range map[string]string{
		"json":           `{"password":"fixture alpha beta", "token": "fixture gamma delta", "status":"running"}`,
		"escaped-json":   string(escaped),
		"numeric-json":   `{"token":123456,"status":"running"}`,
		"multiline-json": "{\n\"password\":\n\"fixture alpha beta\",\n\"status\":\"running\"\n}",
		"quoted-log":     `password="fixture alpha beta" token='fixture gamma delta' status=running`,
		"yaml":           "'password': 'fixture alpha beta', \"token\": \"fixture gamma delta\", status: running",
		"yaml-quotes":    "'password': 'fixture alpha '' beta', status: running",
		"plain":          "password=fixture-alpha token: fixture-gamma status=running",
	} {
		t.Run(name, func(t *testing.T) {
			redactor := NewRedactor()
			masked := redactor.String(line)
			for _, secret := range []string{"fixture", "alpha", "beta", "gamma", "delta"} {
				if strings.Contains(masked, secret) {
					t.Fatal("quoted credential or a fragment survived redaction")
				}
			}
			if !strings.Contains(masked, "running") || !strings.Contains(masked, "[masked]") {
				t.Fatal("non-secret diagnostic context was lost")
			}
			if json.Valid([]byte(line)) && !json.Valid([]byte(masked)) {
				t.Fatal("redaction broke valid structured JSON")
			}
			if redactor.String(masked) != masked {
				t.Fatal("redaction changed an already masked value")
			}
		})
	}
}

func TestRedactorQuotedValuesPreserveUnrelatedFields(t *testing.T) {
	line := `{"password":"fixture alpha beta","status":"running","token_count":4,"tokenizer":"ordinary"}`
	masked := NewRedactor().String(line)
	var fields map[string]any
	if err := json.Unmarshal([]byte(masked), &fields); err != nil {
		t.Fatal(err)
	}
	if fields["password"] != "[masked]" || fields["status"] != "running" || fields["token_count"] != float64(4) || fields["tokenizer"] != "ordinary" {
		t.Fatal("redaction damaged unrelated structured fields")
	}
}

func TestRedactorMasksAnUnterminatedQuotedValueToTheEnd(t *testing.T) {
	for _, line := range []string{`password="fixture alpha beta`, `password='fixture alpha beta`, `password="fixture alpha beta\`, `password='fixture alpha beta\`} {
		if strings.Contains(NewRedactor().String(line), "fixture") || strings.Contains(NewRedactor().String(line), "beta") {
			t.Fatal("unterminated quoted value leaked a fragment")
		}
	}
}
