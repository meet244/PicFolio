
# PicFolio 📷

  ![Frame 5](https://github.com/meet244/PicFolio/assets/83262693/616cd93f-2544-41db-82ec-d0b2c2a35962)

**PicFolio** is a self-hosted, privacy-first photo management app — a local Google Photos alternative. It runs entirely on your own machine, giving you AI-powered photo organization, face grouping, smart search, duplicate detection, and a clean web UI, without paying for cloud storage or sharing your photos with anyone.

  

---

  

## Screenshots

  - ### Desktop💻
<img src="https://github.com/meet244/PicFolio/assets/83262693/c4d21236-8be9-4692-a13e-bd5845969456" width="400">

- ### Web 🌐

  

---

  

## Features

  

-  **Multi-user support** — Separate photo libraries per user, each with their own login

-  **AI Auto-tagging** — Every photo is tagged automatically using the Recognize Anything Model (RAM)

-  **Face Grouping** — Detects and clusters people across your library using DeepFace; name them for easy browsing

-  **Natural Language Search** — Search photos by description ("dog at beach") powered by Gemini Pro + semantic embeddings

-  **Auto Albums** — Photos grouped automatically by scene and content

-  **Places / GPS Map** — Browse photos by location using EXIF GPS data on an interactive map

-  **Duplicate Detection** — Find and remove duplicate photos

-  **Blur Detection** — Surface and clean up low-quality, blurry shots

-  **Favorites & Bin** — Like photos, delete to bin, restore anytime

-  **Upload** — Drag and drop upload from browser (works on mobile too)

-  **Statistics** — View storage usage and library stats

-  **100% Local** — Nothing leaves your machine (except an optional Gemini API key for search)

  

---

  

## Tech Stack

  

| Layer | Technology |

|---|---|

| Backend | Python, Flask, SQLite, Waitress |

| AI / ML | RAM (Recognize Anything Model), DeepFace, Gemini Pro, SentenceTransformers |

| Frontend | Next.js 15, React 19, Tailwind CSS |

| Maps | Leaflet / React Leaflet |

| Media | Pillow, MoviePy, OpenCV |

  

---

  

## Installation

  

### Prerequisites

  

- Python 3.10+

- Node.js 18+

- A [Gemini API key](https://aistudio.google.com/app/apikey) (free, optional — only needed for AI search)

  

---

  

### Backend Setup

  

**1. Create and activate a virtual environment**

  

```bash

# Windows

python  -m  venv  venv

venv\Scripts\activate

  

# macOS / Linux

python  -m  venv  venv

source  venv/bin/activate

```

  

**2. Install Python dependencies**

  

```bash

pip  install  -r  Backend/requirements.txt

```

  

**3. Configure environment variables**

  

Create a `.env` file inside the `Backend/` folder:

  

```env

Gemini=your_gemini_api_key_here

```

  

**4. Run the backend**

  

```bash

python  backend/start.py

```

  

The backend server will start on `http://localhost:5000`.

  

---

  

### Frontend Setup

  

**1. Navigate to the frontend directory**

  

```bash

cd  Frontend

```

  

**2. Install dependencies**

  

```bash

npm  i

```

  

**3. Run the development server**

  

```bash

npm  run  dev

```

  

The frontend will be available at `http://localhost:3000`.

  

---

  

## First-Time Setup

  

1. Open `http://localhost:3000` in your browser

2. Go to the **Setup** page and enter your backend server URL (`http://localhost:5000`)

3. Create your first user

4. Start uploading photos

  

---

  

## Contributions

  

Contributions are welcome! Whether it's bug fixes, feature enhancements, or documentation improvements, feel free to submit a pull request.

  

---