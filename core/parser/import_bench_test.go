package parser

import (
	"encoding/base64"
	"strconv"
	"strings"
	"testing"
)

// subscription200 builds a realistic plain-list subscription with 200
// servers using several protocols and query-parameter shapes, as produced
// by typical providers.
func subscription200() []byte {
	var b strings.Builder
	for i := 0; i < 200; i++ {
		id := "123e4567-e89b-12d3-a456-" + strconv.Itoa(426614174000+i)
		switch i % 5 {
		case 0:
			b.WriteString("vless://" + id + "@node" + strconv.Itoa(i) + ".example.com:443?type=tcp&security=reality&pbk=pubkey" + strconv.Itoa(i) + "&fp=chrome&sni=www.example.com&sid=short" + strconv.Itoa(i) + "&spx=%2F&flow=xtls-rprx-vision#%F0%9F%87%B3%F0%9F%87%B1%20Server" + strconv.Itoa(i) + "\n")
		case 1:
			b.WriteString("vmess://" + id + "@node" + strconv.Itoa(i) + ".example.com:443?type=ws&security=tls&path=%2Fws&host=cdn.example.com&sni=cdn.example.com#VMess" + strconv.Itoa(i) + "\n")
		case 2:
			b.WriteString("trojan://pass" + strconv.Itoa(i) + "@node" + strconv.Itoa(i) + ".example.com:443?security=tls&sni=www.example.com&alpn=h2,http%2F1.1#Trojan" + strconv.Itoa(i) + "\n")
		case 3:
			b.WriteString("ss://YWVzLTI1Ni1nY206cGFzczEyMzQ1Ng%3D%3D@node" + strconv.Itoa(i) + ".example.com:8388#SS" + strconv.Itoa(i) + "\n")
		default:
			b.WriteString("hysteria2://hy2pass" + strconv.Itoa(i) + "@node" + strconv.Itoa(i) + ".example.com:8443?insecure=1&obfs=salamander&obfs-password=<redacted>" + strconv.Itoa(i) + "#HY2" + strconv.Itoa(i) + "\n")
		}
	}
	return []byte(b.String())
}

// BenchmarkParseSubscription200 measures the hot import path for a
// realistic 200-server subscription, including detection and per-link
// query parsing.
func BenchmarkParseSubscription200(b *testing.B) {
	src := subscription200()
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		r, err := (LinkParser{}).Parse(src)
		if err != nil {
			b.Fatal(err)
		}
		if len(r.Servers) != 200 {
			b.Fatalf("servers = %d", len(r.Servers))
		}
	}
}

// BenchmarkParseBase64List2000 measures the base64-list import path with
// 2000 unique links (the shape large providers actually ship).
func BenchmarkParseBase64List2000(b *testing.B) {
	var sb strings.Builder
	for block := 0; block < 10; block++ {
		for i := 0; i < 200; i++ {
			n := block*200 + i
			id := "123e4567-e89b-12d3-a456-" + strconv.Itoa(426614174000+n)
			sb.WriteString("vless://" + id + "@node" + strconv.Itoa(n) + ".example.com:443?type=tcp&security=reality&pbk=pubkey" + strconv.Itoa(n) + "&fp=chrome&sni=www.example.com&sid=short" + strconv.Itoa(n) + "&spx=%2F&flow=xtls-rprx-vision#Server" + strconv.Itoa(n) + "\n")
		}
	}
	src := []byte(base64.StdEncoding.EncodeToString([]byte(sb.String())))
	_ = src
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		r, err := (LinkParser{}).Parse(src)
		if err != nil {
			b.Fatal(err)
		}
		if len(r.Servers) != 2000 {
			b.Fatalf("servers = %d", len(r.Servers))
		}
	}
}
