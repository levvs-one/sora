package obfs

import (
	"bytes"
	"crypto/rand"
	"crypto/rsa"
	"crypto/tls"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/binary"
	"encoding/pem"
	"math/big"
	"sync"
	"testing"
	"time"
)

// testClientHelloRecord builds a minimal but well-formed TLS ClientHello
// record with the given SNI. When trailing is true, a supported_versions
// extension is appended after server_name to exercise length splicing.
func testClientHelloRecord(t *testing.T, sni string, trailing bool) []byte {
	t.Helper()
	name := []byte(sni)
	snEntry := []byte{0, byte(len(name) >> 8), byte(len(name))}
	snEntry = append(snEntry, name...)
	snListLen := len(snEntry)
	snData := []byte{byte(snListLen >> 8), byte(snListLen)}
	snData = append(snData, snEntry...)
	snExt := []byte{0, 0, byte(len(snData) >> 8), byte(len(snData))}
	snExt = append(snExt, snData...)

	exts := snExt
	if trailing {
		// supported_versions with TLS 1.3 + 1.2.
		exts = append(exts, 0x00, 0x2b, 0x00, 0x03, 0x02, 0x03, 0x04)
	}

	body := []byte{0x03, 0x03}
	random := make([]byte, 32)
	if _, err := rand.Read(random); err != nil {
		t.Fatal(err)
	}
	body = append(body, random...)
	body = append(body, 0x00)                   // session id length
	body = append(body, 0x00, 0x02, 0x13, 0x01) // cipher suites
	body = append(body, 0x01, 0x00)             // compression
	body = append(body, byte(len(exts)>>8), byte(len(exts)))
	body = append(body, exts...)

	hs := []byte{handshakeClientHello, byte(len(body) >> 16), byte(len(body) >> 8), byte(len(body))}
	hs = append(hs, body...)
	rec := []byte{recordTypeHandshake, 0x03, 0x01, byte(len(hs) >> 8), byte(len(hs))}
	rec = append(rec, hs...)
	return rec
}

// testClientHelloRecordNoSNI builds a ClientHello record without a
// server_name extension.
func testClientHelloRecordNoSNI(t *testing.T) []byte {
	t.Helper()
	exts := []byte{0x00, 0x2b, 0x00, 0x03, 0x02, 0x03, 0x04}
	body := []byte{0x03, 0x03}
	random := make([]byte, 32)
	if _, err := rand.Read(random); err != nil {
		t.Fatal(err)
	}
	body = append(body, random...)
	body = append(body, 0x00, 0x00, 0x02, 0x13, 0x01, 0x01, 0x00)
	body = append(body, byte(len(exts)>>8), byte(len(exts)))
	body = append(body, exts...)
	hs := []byte{handshakeClientHello, byte(len(body) >> 16), byte(len(body) >> 8), byte(len(body))}
	hs = append(hs, body...)
	rec := []byte{recordTypeHandshake, 0x03, 0x01, byte(len(hs) >> 8), byte(len(hs))}
	return append(rec, hs...)
}

// testRecordSNI extracts the SNI hostname from a ClientHello record.
func testRecordSNI(t *testing.T, record []byte) string {
	t.Helper()
	body := record[recordHeaderLen+4:]
	_, extOff, extLen, err := findServerNameExt(body)
	if err != nil {
		t.Fatalf("findServerNameExt: %v", err)
	}
	data := body[extOff+4 : extOff+4+extLen]
	listLen := int(binary.BigEndian.Uint16(data))
	if 2+listLen != len(data) {
		t.Fatalf("server_name list length mismatch")
	}
	nameLen := int(binary.BigEndian.Uint16(data[3:5]))
	name := data[5 : 5+nameLen]
	if !bytes.Equal(data[2:3], []byte{0}) {
		t.Fatalf("unexpected name type")
	}
	return string(name)
}

// testServerCert generates a self-signed certificate for example.com.
func testServerCert(t *testing.T) tls.Certificate {
	t.Helper()
	return testServerCertCached(t)
}

var testCertCache struct {
	once sync.Once
	cert tls.Certificate
	err  error
}

// testServerCertCached generates the test certificate once per test binary
// run: RSA key generation can stall on entropy-starved machines, and every
// test needs the same cert anyway.
func testServerCertCached(t *testing.T) tls.Certificate {
	t.Helper()
	testCertCache.once.Do(func() {
		testCertCache.cert, testCertCache.err = buildTestCert()
	})
	if testCertCache.err != nil {
		t.Fatal(testCertCache.err)
	}
	return testCertCache.cert
}

// buildTestCert generates a self-signed certificate for example.com.
func buildTestCert() (tls.Certificate, error) {
	key, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		return tls.Certificate{}, err
	}
	tmpl := x509.Certificate{
		SerialNumber:          big.NewInt(1),
		Subject:               pkix.Name{CommonName: "example.com"},
		DNSNames:              []string{"example.com"},
		NotBefore:             time.Now().Add(-time.Hour),
		NotAfter:              time.Now().Add(time.Hour),
		KeyUsage:              x509.KeyUsageDigitalSignature | x509.KeyUsageKeyEncipherment,
		ExtKeyUsage:           []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth},
		BasicConstraintsValid: true,
	}
	der, err := x509.CreateCertificate(rand.Reader, &tmpl, &tmpl, &key.PublicKey, key)
	if err != nil {
		return tls.Certificate{}, err
	}
	cert, err := tls.X509KeyPair(
		pemEncode("CERTIFICATE", der),
		pemEncode("RSA PRIVATE KEY", x509.MarshalPKCS1PrivateKey(key)),
	)
	if err != nil {
		return tls.Certificate{}, err
	}
	return cert, nil
}

func pemEncode(block string, der []byte) []byte {
	return pem.EncodeToMemory(&pem.Block{Type: block, Bytes: der})
}
