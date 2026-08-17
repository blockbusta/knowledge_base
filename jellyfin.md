# Jellyfin on Raspberry Pi — Setup & Replication Guide

A from-scratch guide to running **Jellyfin** as a media server on a Raspberry Pi,
serving media stored on locally-attached USB drives to clients on the LAN
(e.g. an NVIDIA Shield). Written to reproduce the working setup we built.

---

## 1. Architecture & the golden rule

```
 ┌────────────────────────────┐          LAN           ┌─────────────────────────┐
 │  Raspberry Pi               │  <------------------>  │  NVIDIA Shield (client) │
 │  - Jellyfin SERVER (:8096)  │                        │  - Jellyfin app         │
 │  - USB drives (the media)   │                        │    (plays from the Pi)  │
 └────────────────────────────┘                        └─────────────────────────┘
```

**Golden rule:** the media lives on the Pi, so **the Pi is the server** and the
Shield is only a **client**. Create your libraries on the Pi's Jellyfin, never on
the client device. (We lost time earlier because libraries were created on the
Shield's server, which cannot see the Pi's local disks — the library was always
empty.)

Why the Pi as server: media is on local disks (fastest, no network mounts needed),
and the Shield "direct plays" almost everything, so the Pi rarely has to transcode.

---

## 2. Hardware & environment we used

| Item | Value |
|---|---|
| Board | Raspberry Pi (ARM, 64-bit capable) |
| OS | Raspberry Pi OS 12 "bookworm" (Debian 12), 32-bit armhf userland |
| Server IP | `192.168.68.120` |
| Client | NVIDIA Shield (Android TV, Jellyfin app) |
| Storage | 2× USB drives, ext4 |
| Jellyfin web port | `8096` (HTTP, LAN only — not exposed to the internet) |

---

## 3. Prerequisites

- Raspberry Pi OS (bookworm) installed and booting.
- SSH access to the Pi (`ssh <user>@<pi-ip>`).
- Two (or more) USB drives already containing your media, formatted **ext4**.
- A wired Ethernet connection strongly recommended (see §9).
- Basic familiarity with the terminal and `sudo`.

---

## 4. Prepare the OS

### 4.1 Sanity-check / fix APT sources (do this first)

A broken or outdated repo will make `apt` hang or fail, blocking the Jellyfin
install. Make sure `/etc/apt/sources.list` only contains **current** entries for
your release (`bookworm`), with **no** end-of-life releases (e.g. `buster`) and
**no** duplicate mirrors.

A clean `/etc/apt/sources.list` for Raspberry Pi OS bookworm:

```
# Raspberry Pi OS (Raspbian) - bookworm
deb [signed-by=/usr/share/keyrings/raspbian-archive-keyring.gpg] http://raspbian.raspberrypi.org/raspbian/ bookworm main contrib non-free rpi
#deb-src [signed-by=/usr/share/keyrings/raspbian-archive-keyring.gpg] http://raspbian.raspberrypi.org/raspbian/ bookworm main contrib non-free rpi
```

And `/etc/apt/sources.list.d/raspi.list`:

```
deb http://archive.raspberrypi.org/debian/ bookworm main
```

> Tip: back up before editing — `sudo cp -a /etc/apt/sources.list /etc/apt/sources.list.bak`.
> The `signed-by=` key silences the legacy `trusted.gpg` deprecation warning.

### 4.2 Update the system

```bash
sudo apt update
sudo apt full-upgrade -y
sudo apt autoremove -y
```

Reboot if the kernel or firmware was upgraded: `sudo reboot`.

---

## 5. Mount the media drives persistently

### 5.1 Identify the drives (do NOT wipe/format existing drives)

```bash
lsblk -f          # shows FSTYPE, LABEL, UUID, current mountpoints
sudo blkid        # UUIDs for fstab
```

You are looking for each partition's **UUID** and confirming it's `ext4`.
If the drives already hold data, **skip all "wipe/format" steps** in generic
guides — those are only for brand-new empty drives.

### 5.2 Create mount points

```bash
sudo mkdir -p /mnt/500apple /mnt/tera
```

### 5.3 Add to `/etc/fstab` (auto-mount on boot)

Edit `/etc/fstab` and add one line per drive, using **your** UUIDs:

```
UUID=<uuid-of-drive-1> /mnt/500apple ext4 defaults,auto,users,rw,nofail,noatime 0 0
UUID=<uuid-of-drive-2> /mnt/tera     ext4 defaults,auto,users,rw,nofail,noatime 0 0
```

Key options:
- `nofail` — the Pi still boots if a drive is missing (avoids boot hangs).
- `noatime` — don't write access timestamps on every read (less wear, faster).

### 5.4 Mount and verify

```bash
sudo mount -a
lsblk -f          # confirm both are mounted at the right paths
df -h /mnt/500apple /mnt/tera
```

---

## 6. Permissions so Jellyfin can read the media

Jellyfin runs as the system user **`jellyfin`**. It needs **read (`r`)** on files
and **traverse (`x`)** on every directory in the path.

### 6.1 Check what Jellyfin can see

```bash
id jellyfin
sudo -u jellyfin test -r /mnt/tera && sudo -u jellyfin test -x /mnt/tera \
  && echo "jellyfin CAN read /mnt/tera" || echo "jellyfin CANNOT read /mnt/tera"
```

### 6.2 Make the media readable (two valid approaches)

**Approach A — shared group (recommended, survives permission tightening):**
We used a group called `storagegroup` owning the media, with the setgid bit on
directories so new files inherit the group.

```bash
# add jellyfin to the media group
sudo usermod -aG storagegroup jellyfin
sudo systemctl restart jellyfin
# ensure the group can read/traverse (only if needed)
sudo chgrp -R storagegroup /mnt/tera /mnt/500apple
sudo chmod -R g+rX /mnt/tera /mnt/500apple
sudo find /mnt/tera /mnt/500apple -type d -exec chmod g+s {} \;
```

**Approach B — world-readable (simplest):** ensure "other" has `r-x`:

```bash
sudo chmod -R o+rX /mnt/tera /mnt/500apple
```

> Our drives were already `drwxrwsr-x root:storagegroup` (world `r-x`), so
> `jellyfin` could read them out of the box. Either approach works.

### 6.3 (Optional) NFS export — unrelated to Jellyfin

If the drives are also NFS-exported (for other machines), that keeps working
alongside Jellyfin; both can read the same files simultaneously. Nothing to do
here for Jellyfin itself.

---

## 7. Install Jellyfin

Use the official Jellyfin Debian/Ubuntu installer (adds the repo and installs the
server + `jellyfin-ffmpeg`):

```bash
sudo apt install -y curl gnupg
curl -fsSL https://repo.jellyfin.org/install-debuntu.sh | sudo bash
```

Enable and start the service (the installer usually does this):

```bash
sudo systemctl enable --now jellyfin
systemctl status jellyfin --no-pager
```

Jellyfin is now at:

```
http://<pi-ip>:8096
```

Data / config locations (useful for backup — see §11):
- Data & DB: `/var/lib/jellyfin/` (`data/jellyfin.db` holds users & settings)
- Server config: `/etc/jellyfin/`
- Cache: `/var/cache/jellyfin/`
- Logs: `/var/log/jellyfin/`

---

## 8. First-run wizard & libraries

Open `http://<pi-ip>:8096` in a browser and complete setup:

1. **Create the admin user** (we used username `jellyfin`) and set a password.
2. **Add libraries** — this is where the media layout matters. Point each library
   at the **Pi's local paths**.

### 8.1 Recommended library layout

| Library | Content type | Folders to add |
|---|---|---|
| **Movies** | Movies | `/mnt/tera/4k_movies` (optionally `/mnt/500apple/finished`) |
| **TV Shows** | Shows | organized show folders, e.g. `/mnt/tera/family_guy`, `/mnt/tera/futurama`, `/mnt/tera/simpsons`, `/mnt/tera/south_park`, `/mnt/tera/rick_and_morty`, `/mnt/tera/bojack_horseman`, `/mnt/tera/eretz_nehederet` (optionally `/mnt/500apple/finished`) |
| **Other Videos** | Home Videos / mixed | `/mnt/500apple/finished` (the messy download dump) |

Notes:
- **Do NOT add `/mnt/500apple/incomplete`** — those are in-progress downloads.
- You can add the same messy folder (`finished`) to both a Movies and a TV
  library; each grabs only what matches its type. For the truly unsorted stuff,
  the **Other Videos / mixed** library lists everything without strict matching.
- Jellyfin scans **subfolders recursively**, so nested folders are fine. Matching
  quality depends on naming (see below).

### 8.2 Naming that matches well (for Movies/TV libraries, not "Other Videos")

- Movies: `Movie Name (Year).ext` (e.g. `Sinners (2025).mkv`).
- TV: `Show Name/Season 01/Show Name - S01E02.ext`.
- Scene-style dotted names usually match too (`Better.Call.Saul.S01E01...`).
- Anything that won't match can be fixed later via **Identify** on the item.

---

## 9. Performance & CPU tuning (keep the Pi cool and idle)

### The #1 rule: never let the Pi transcode
A Pi is a poor transcoder (no real HEVC hardware encoder). The Shield direct-plays
almost everything, so keep it in **Direct Play** and the Pi stays nearly idle.

### 9.1 Client (Shield app) settings — where transcodes get triggered
- Set **max streaming bitrate to Auto/maximum** (a cap below the file bitrate
  forces a server transcode).
- **Avoid image-based subtitles (PGS/VOBSUB/SUP)** — enabling them forces a full
  video transcode (they get "burned in"). Prefer **text subs (SRT/ASS)** or none.
- Keep **Direct Play / Direct Stream** allowed.

### 9.2 Server settings — disable heavy background jobs
In **Dashboard**:
- **Playback → Trickplay:** disable (or run low-res/single-threaded only during
  scans). The scrubbing-preview generation is the biggest CPU hog on a Pi.
- **Libraries → (each library):** turn **off "Enable chapter image extraction."**
- **Scheduled Tasks:** disable/space out anything you don't need; keep the nightly
  library scan, drop the extras.
- Trim metadata/image providers per library to only what you use.

### 9.3 If a transcode is ever unavoidable — use RAM for temp files
Point Jellyfin's transcode temp at a tmpfs (RAM) instead of the SD card.

Create a RAM-backed folder via `/etc/fstab` (size to taste / RAM available):

```
tmpfs /mnt/jf-transcode tmpfs defaults,noatime,size=2G,uid=jellyfin,gid=jellyfin,mode=0755 0 0
```

```bash
sudo mkdir -p /mnt/jf-transcode
sudo mount -a
```

Then in **Dashboard → Playback → Transcoding → "Transcoding temporary path"**, set
it to `/mnt/jf-transcode`. Also set **Hardware acceleration = None** on the Pi
(the software path is more reliable than the Pi's weak encoder).

> This only matters when transcoding actually happens; it's harmless otherwise.

### 9.4 Physical / network
- **Wired Gigabit Ethernet** for the Pi. 4K remuxes hit 50–80 Mbps; Wi-Fi
  bottlenecks cause buffering, and clients often "fix" buffering by requesting a
  lower quality → transcode.
- **Keep the Pi cool.** A hot Pi thermally throttles (lower clock = slower).
  Check with:
  ```bash
  vcgencmd measure_temp
  vcgencmd get_throttled   # 0x0 = never throttled; non-zero = throttling
  ```
  Add a heatsink/fan if it throttles.
- If the OS is on a slow SD card, consider booting from USB/SSD for snappier
  metadata/artwork I/O.

---

## 10. Verify it's working

- Play something on the Shield, then open **Dashboard → Activity / Sessions**:
  - **"Direct Play"** → the Pi is basically idle (goal achieved).
  - **"Transcode"** → something is forcing it (bitrate cap or bitmap subtitle) —
    fix that stream (§9.1) and CPU load drops away.
- Confirm libraries populated. If a library is empty:
  - Are you on the **Pi's** server (not the client)?
  - Does the path exist on the Pi and can `jellyfin` read it (§6.1)?
  - Trigger **Scan Library** from the library's menu.

---

## 11. Backup & recovery

### 11.1 Back up Jellyfin config/DB

```bash
sudo systemctl stop jellyfin
sudo tar czf ~/jellyfin-backup-$(date +%F).tar.gz \
  /etc/jellyfin /var/lib/jellyfin/data /var/lib/jellyfin/config /var/lib/jellyfin/plugins
sudo systemctl start jellyfin
```

Restore = stop Jellyfin, extract the tarball back to the same paths, fix ownership
(`sudo chown -R jellyfin:jellyfin /var/lib/jellyfin`), start Jellyfin.

### 11.2 Reset a forgotten Jellyfin password
Log in as another admin and reset it in **Dashboard → Users**, or (if locked out)
reset the admin password by clearing the stored hash in `jellyfin.db` while the
service is stopped, then set a new one on next login. (Ask for the exact SQL if
needed — usernames live in the `Users` table of `/var/lib/jellyfin/data/jellyfin.db`.)

---

## 12. Troubleshooting quick reference

| Symptom | Likely cause / fix |
|---|---|
| Library is empty but files exist | Built on the **wrong server** (client vs Pi); or path/permission — check §6.1 |
| `apt` hangs/fails | Broken/EOL/duplicate repo entries — fix §4.1 |
| High Pi CPU during playback | A **transcode** is happening — bitrate cap or bitmap subtitle (§9.1) |
| Playback buffers on 4K | Wi-Fi bottleneck — use wired Ethernet (§9.4) |
| Drive missing after reboot | Missing/incorrect `fstab` UUID; ensure `nofail` (§5.3) |
| Everything slow / stutters | Pi thermally throttling — check `vcgencmd get_throttled` (§9.4) |

---

## Appendix A — Our specific values

| Setting | Value |
|---|---|
| Pi hostname / server name | `raspberrypi` |
| Pi IP | `192.168.68.120` |
| Jellyfin URL | `http://192.168.68.120:8096` |
| Jellyfin admin username | `jellyfin` |
| Drive 1 | `ext4`, UUID `14d2804e-2b69-5b4a-b8c7-add17dd14657` → `/mnt/500apple` |
| Drive 2 | `ext4`, UUID `44d82b17-e443-48ff-9720-a6672779f079` → `/mnt/tera` |
| Media group | `storagegroup` (setgid dirs, world `r-x`) |
| Client | NVIDIA Shield, Jellyfin Android TV app |
| Exposure | LAN only (not internet-facing) |

## Appendix B — fstab lines we used

```
UUID=14d2804e-2b69-5b4a-b8c7-add17dd14657 /mnt/500apple ext4 defaults,auto,users,rw,nofail,noatime 0 0
UUID=44d82b17-e443-48ff-9720-a6672779f079 /mnt/tera     ext4 defaults,auto,users,rw,nofail,noatime 0 0
```

## Appendix C — media layout reference

```
/mnt/tera/                 # cleanly organized (great for Movies/TV libraries)
  4k_movies/               #   -> Movies library
  family_guy/ futurama/ simpsons/ south_park/ rick_and_morty/
  bojack_horseman/ eretz_nehederet/ standup/   # -> TV Shows library

/mnt/500apple/
  finished/                # mixed download dump -> "Other Videos"/mixed library
  incomplete/              # in-progress downloads -> DO NOT add to Jellyfin
```
