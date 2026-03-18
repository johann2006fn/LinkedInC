import base64
import json

diagrams = [
"""graph TD
    User["User (Candidate)"] -- "Inputs: CollegeCode, ID, InviteCode" --> Gate["Verification Processor"]
    
    subgraph Firestore ["Firebase Infrastructure"]
        Colleges[("(D1) colleges Collection")]
        Identities[("(D2) identities Subcollection")]
        Users[("(D3) users Collection")]
    end

    Gate -- "1. Validate College Code" --> Colleges
    Gate -- "2. Read Identity Data" --> Identities
    
    Identities -- "Data: isClaimed, inviteCode" --> Gate
    
    Gate -- "3. Logic Check: inviteCode == input && !isClaimed" --> Logic{Valid?}
    
    Logic -- "Yes" --> Trans["Start Transaction"]
    Logic -- "No" --> Fail["Return Error (SnackBar)"]
    
    Trans -- "4. Update isClaimed=true, claimedBy=UID" --> Identities
    Trans -- "5. Set isVerifiedCollegeUser=true, name, role" --> Users
    
    Trans -- "6. Success Acknowledgement" --> User
    User -- "Reroute to Dashboard" --> App""",
"""graph TD
    Time["System Clock (Real-time)"] --> Offset["Delta Calculator"]
    ProposedTime["(D4) Chat Metadata: proposedTime"] --> Offset
    
    Offset -- "diff = proposedTime - now" --> Threshold{Within Window?}
    
    subgraph Thresholds ["Temporal Guards"]
        Lower["-5 Minutes (Pre-session)"]
        Upper["+60 Minutes (Post-start)"]
    end
    
    Threshold -- "diff <= 5m AND diff >= -60m" --> Active["State: ENABLED"]
    Threshold -- "Otherwise" --> Locked["State: LOCKED"]
    
    Active -- "Render: 'Join Video Call' (Green)" --> UI["Session Message Tile"]
    Locked -- "Render: 'Locked' / 'Session Ended' (Grey)" --> UI""",
"""graph TD
    Mentee["Mentee"] -- "Submit Feedback (Tags + Text)" --> Repo["Review Repository"]
    
    subgraph Transaction ["Atomic Write Unit"]
        MentorDoc[("(D3) Mentor Document")]
        PrivateColl[("(D5) private_feedback Collection")]
    end
    
    Repo -- "1. Increment sessionsCompleted" --> MentorDoc
    Repo -- "2. Update endorsements Map (increment specific keys)" --> MentorDoc
    Repo -- "3. Write encrypted feedback" --> PrivateColl
    
    MentorDoc -- "Update UI Stats" --> Discovery["Mentor Dashboard View"]""",
"""graph TD
    MenteeProfile["(D3) Mentee Preferences/Bio"] --> Embedder["Gemini Embedding API"]
    MentorPool["(D3) Mentor Skills/Tags Pool"] --> Embedder
    
    Embedder -- "Vector v1 (Mentee)" --> Matcher["Similarity Processor"]
    Embedder -- "Vector set V2 (Mentors)" --> Matcher
    
    Matcher -- "Cosine Similarity Calculation" --> Scorer["Ranking Algorithm"]
    
    Scorer -- "Top-N Matches" --> Sort["Sorted Mentor Result Set"]
    Sort -- "Display as 'Recommended for You'" --> UI["Explore Screen"]"""
]

for i, d in enumerate(diagrams):
    # Mermaid.ink uses a specific JSON format: {"code": "...", "mermaid": {"theme": "default"}}
    msg = json.dumps({"code": d, "mermaid": {"theme": "default"}})
    encoded = base64.urlsafe_b64encode(msg.encode('utf-8')).decode('utf-8')
    print(f"URL {i+1}: https://mermaid.ink/img/{encoded}")
