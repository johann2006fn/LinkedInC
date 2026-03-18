<div class="header-meta">
    <div>PROJECT: MENTORHUB ECOSYSTEM</div>
    <div>ID: MH-TEST-2026-03<br>REV: 1.2.0<br>DATE: March 15, 2026</div>
</div>

# QA Testing Report
**Overall Status:** <span class="status-pass">PASSED</span>

---

## 1. Authentication & Identity
Ensures secure role-based access control and college identity verification.

| Test Case | ID | Input | Expected Result | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Valid Identity Claim** | TC-01 | Correct Code/ID/Invite | Profile created; Reroute | **PASS** |
| **Duplicate Claim** | TC-02 | Used identity ID | Error: "Already claimed" | **PASS** |
| **Invite Mismatch** | TC-03 | Wrong 6-digit key | Snackbar: "Invalid Code" | **PASS** |
| **Empty Inputs** | TC-04 | Null fields | Prompt: "Fill all fields" | **PASS** |

## 2. Matchmaking Precision
Validation of the Cosine Similarity algorithm for mentor-mentee pairing.

| Test Case | ID | Relationship | Score | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Identical Profiles** | MC-01 | Exact match | 1.0000 | **PASS** |
| **Orthogonal** | MC-02 | Zero overlap | 0.0000 | **PASS** |
| **Inversed** | MC-03 | Opposite traits | -1.0000 | **PASS** |
| **Partial (45°)** | MC-04 | High similarity | 0.7071 | **PASS** |

## 3. Video Call Temporal Windows
Enforcement of join-window restrictions (T-5 to T+60).

| Test Case | ID | Scenario | Result | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Pre-window** | VC-01 | T-10 mins | Action Locked | **PASS** |
| **Join Window** | VC-02 | T-5 mins | Action Enabled | **PASS** |
| **Post-window** | VC-03 | T+61 mins | Session Expired | **PASS** |
| **ID Sanitization** | VC-04 | `chat_123!` | `mentorhub-chat123`| **PASS** |

<div class="alert">
    <span class="alert-title">Technical Note</span>
    Testing executed using the Automated Flutter Test Suite. Backend responses mocked via Mockito to ensure deterministic vector analysis.
</div>

---
*Mentorship App | Quality Assurance Division | Confidential*
