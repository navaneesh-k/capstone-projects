# Project 24 – Manual Chaos Test

**Incident ID:** INC-024

**Environment:** Ubuntu VM

**Affected Service:** project24-nk

**Incident Type:** Simulated service failure

**Incident Start Time:** Tue Nov 24 09:33:03 UTC 2026

**Recovery Time:** Tue Nov 24 09:34:15 UTC 2026

**Total Downtime:** 1 minute 12 sec

## Incident Description

A controlled service failure was simulated by manually stopping the web application service using systemctl.

## Impact

The web application became unavailable, and HTTP requests failed with a connection error.

## Root Cause

Intentional termination of the web application service as part of a manual chaos test.

## Recovery Action

The service was manually restarted using systemctl restart project24-nk.

## Recovery Verification

- Service status returned to active.
- HTTP requests succeeded.
- The application webpage became accessible again.

## Incident Status

Resolved.

## Lessons Learned

Service monitoring and timely restart procedures help reduce application downtime and improve operational reliability.
