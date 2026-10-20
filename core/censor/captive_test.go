package censor

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
)

func captiveClient() *http.Client {
	return &http.Client{
		Transport: &http.Transport{Proxy: nil},
		CheckRedirect: func(*http.Request, []*http.Request) error {
			return http.ErrUseLastResponse
		},
	}
}

func TestCaptivePortalExactAnswerIsNone(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	}))
	defer srv.Close()
	eps := []captiveEndpoint{{name: "test", url: srv.URL, wantStatus: http.StatusNoContent}}
	rep := DetectCaptivePortal(context.Background(), eps, captiveClient())
	if rep.State != CaptiveNone {
		t.Fatalf("state = %v, want none (%v)", rep.State, rep.Evidence)
	}
}

func TestCaptivePortalRedirectIsPortal(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Location", "http://portal.example/login")
		w.WriteHeader(http.StatusFound)
	}))
	defer srv.Close()
	eps := []captiveEndpoint{{name: "test", url: srv.URL, wantStatus: http.StatusNoContent}}
	rep := DetectCaptivePortal(context.Background(), eps, captiveClient())
	if rep.State != CaptivePortal {
		t.Fatalf("a redirect is a portal, got %v", rep.State)
	}
}

func TestCaptivePortalForeignBodyIsPortal(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, _ = w.Write([]byte("<html>Please log in to HotelWiFi</html>"))
	}))
	defer srv.Close()
	eps := []captiveEndpoint{{name: "test", url: srv.URL, wantStatus: http.StatusOK, wantBody: "Success"}}
	rep := DetectCaptivePortal(context.Background(), eps, captiveClient())
	if rep.State != CaptivePortal {
		t.Fatalf("a foreign body is a portal, got %v", rep.State)
	}
}

func TestCaptivePortalSilenceIsUnknown(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {}))
	url := srv.URL
	srv.Close() // nothing listens now
	eps := []captiveEndpoint{{name: "test", url: url, wantStatus: http.StatusNoContent}}
	rep := DetectCaptivePortal(context.Background(), eps, captiveClient())
	if rep.State != CaptiveUnknown {
		t.Fatalf("silence must stay unknown, got %v", rep.State)
	}
}

func TestCaptivePortalExpectedBodyIsNone(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, _ = w.Write([]byte("<HTML><HEAD><TITLE>Success</TITLE></HEAD><BODY>Success</BODY></HTML>"))
	}))
	defer srv.Close()
	eps := []captiveEndpoint{{name: "apple", url: srv.URL, wantStatus: http.StatusOK, wantBody: "Success"}}
	rep := DetectCaptivePortal(context.Background(), eps, captiveClient())
	if rep.State != CaptiveNone {
		t.Fatalf("state = %v, want none", rep.State)
	}
}
