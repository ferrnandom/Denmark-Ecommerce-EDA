# Digital Breadcrumbs

Forensics-udfordring, hvor du efterforsker et databrud ved at spore digitale beviser gennem en kompromitteret arbejdsstation. Afkod skjulte spor, navigér i filsystemet og udtræk metadata for at afsløre angriberens identitet.

---

Forensics challenge where you investigate a data breach by tracing digital evidence through a compromised workstation. Decode hidden clues, navigate the file system, and extract metadata to reveal the attacker's identity.

## Flag(s)

- Digital Breadcrumbs: `DDC{d4nger_hacker}`

## Nextcloud Link

> https://nextcloud.haaukins.com/s/95FgdQHd8gBbLBp/download/Misc_Digital_Breadcrumbs.zip
**SHA256** 'B34F05B7DC227ECA14BFCF14421949AEC77D3A1C1501797EBD6B155D83EA9972' 

## Proposed difficulty:

Easy

## Prerequisites & Outcome

### Prerequisites

- Basic Linux command-line knowledge
- Familiarity with file system navigation (cd, ls, find commands)
- exiftool utility installed
- base64 command-line tool
- Understanding of hidden files (dotfiles) in Linux

### Outcome

- How to navigate and locate hidden files in Linux
- Base64 encoding/decoding concepts and practical application
- File metadata analysis using exiftool
- Digital forensics investigative techniques
- Following logical evidence trails to solve challenges
- Command-line proficiency with file searching and filtering

## Solution(s)

### Digital Breadcrumbs

1. Navigate to the Forensics directory and list all files including hidden ones:
   ```bash
   cd Forensics
   ls -la
   ```
   Look for the hidden `.evidence.txt` file (files starting with a dot are hidden in Linux).

2. Decode the Base64-encoded clue from the hidden file:
   ```bash
   cat .evidence.txt | base64 -d
   ```
   This will reveal the location of the suspicious executable, typically something like: `/home/user/forensics/suspicion/malicious_payload.exe`

3. Navigate to the directory specified in the decoded clue:
   ```bash
   cd suspicion
   ```

4. Search for executable files in the current directory:
   ```bash
   find . -type f -name "*.exe"
   ```
   Or alternatively:
   ```bash
   ls -la | grep exe
   ```

5. Install exiftool if not already present (may require sudo):
   ```bash
   sudo apt install exiftool
   ```

6. Extract metadata from the malicious executable and search for the creator/author field:
   ```bash
   exiftool malicious_payload.exe | grep -i "creator\|author\|user"
   ```
   
   Alternative method using strings:
   ```bash
   strings malicious_payload.exe | grep -i "creator"
   ```

7. The Creator/Author field will contain the attacker's username. Wrap it in the flag format:
   ```
   DDC{d4nger_hacker}
   ```
- Identify a POST request send to /login by looking in the info part
- Find the credentials send in the request by looking at the html-www-form-urlencoded  
  layer of the packet
- Use this to login to the website found on either the IP to which the request is going  
  or by finding the request URI in the HTTP layer of the packet
- See the flag in the top left

## How to run locally


> A few lines describing how people can start the challenge locally
