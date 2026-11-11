# LabelLens — Hybrid Food Label Reader

LabelLens reads packaged-food labels with a **React frontend + Python FastAPI backend + PaddleOCR**. It is designed to be more robust than a single browser OCR pass by testing multiple image-processing variants, keeping OCR text/line confidence for review, and parsing nutrition and ingredient images separately.

> **Important:** this is an academic demo, not a medical device. OCR can still omit or misread text. Never treat “no allergen detected” as proof that a food is safe. Check the original package, including precautionary allergen statements.

## What's in this version

- **PaddleOCR 3.x backend** rather than Tesseract.js in the browser.
- Separate uploads for the **nutrition panel** and **ingredients/allergen panel**. The ingredient image is recommended but optional; without it, the app tries to use a single full-label image for both.
- Image normalization with EXIF rotation, resize/upscale for small crops, local contrast enhancement, denoising/sharpening, and adaptive thresholding.
- Auto mode runs multiple preprocessing variants and chooses a result using OCR confidence plus task-specific clues. You can also force one preprocessing mode for comparisons.
- OCR text and bounding boxes are grouped into reading lines, and line-level confidence is retained in the UI.
- Rule-based extraction covers energy, protein, carbohydrates, sugars, fat subtypes, fibre, sodium, salt, cholesterol, several minerals and vitamins.
- **Every supported nutrient is shown.** Fields not confidently detected are shown as “Not found” instead of being invented.
- Unit normalization where reasonably unambiguous (for example, kJ to kcal and sodium g to mg), with a `calculated`/`unit converted` status.
- Basic plausibility checks, confidence/review flags, editable fields, raw OCR correction + re-parse, allergen keyword checks, a sample report, JSON export, and text-report copy.
- No barcode lookup, no paid API, and no cloud account required. After the Paddle model files are downloaded on first use, inference runs locally on your machine.

## Requirements

- Node.js 20.19+ (Node.js 22 LTS is a good choice)
- Python 3.11 recommended (Python 3.10–3.12 are also reasonable choices; PaddlePaddle wheel support depends on your OS/Python combination)
- Internet access on the first backend run so PaddleOCR can download its model weights
- 4 GB+ free RAM recommended; CPU-only inference is supported but the first OCR run can be slow

## Setup (Windows / PowerShell)

Open a terminal in the extracted `labellens` folder.

### 1. Create Python environment

```powershell
py -3.11 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
```

If PowerShell blocks activation, run the commands in a Command Prompt terminal instead:

```bat
.venv\Scripts\activate.bat
```

### 2. Install backend requirements

First install PaddlePaddle's CPU inference engine, then the other packages:

```powershell
python -m pip install paddlepaddle -i https://www.paddlepaddle.org.cn/packages/stable/cpu/
python -m pip install -r backend\requirements.txt
```

If the PaddlePaddle install command says no compatible distribution exists, use the official PaddlePaddle install selector for your operating system and Python version: <https://www.paddlepaddle.org.cn/install/quick>.

### 3. Start the Python API

Keep this terminal open:

```powershell
python -m uvicorn backend.main:app --host 127.0.0.1 --port 8000 --reload
```

Check that <http://127.0.0.1:8000/api/health> opens. The API health endpoint can respond even before the OCR model has been loaded.

### 4. Start React (open a second terminal in the same project folder)

```powershell
npm install
npm run dev
```

Open the URL Vite prints, usually <http://localhost:5173>.

## Setup (macOS / Linux)

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install paddlepaddle -i https://www.paddlepaddle.org.cn/packages/stable/cpu/
python -m pip install -r backend/requirements.txt
python -m uvicorn backend.main:app --host 127.0.0.1 --port 8000 --reload
```

In a second terminal:

```bash
npm install
npm run dev
```

## How to use it

1. Upload a tight, readable crop of the nutrition table.
2. Upload a second close-up of the ingredients + allergen warnings. If omitted, LabelLens reuses the first image and tries to locate the ingredient text there.
3. Start with **Auto compare all variants**. This tests the resized/original image, local contrast + sharpening, and adaptive thresholding.
4. Review every nutrient. Values are editable; each one has a status (Extracted, Unit converted, Review needed, Not found, or Manually edited).
5. Select personal allergen terms to highlight matching clues. Declared allergens, “may contain” statements and ingredient matches are shown separately.
6. If OCR missed text, open **Review / correct**, edit the raw text and choose **Re-parse corrected text**.
7. Export a JSON report or copy a plain-text report for your project/demo.

## Tips to improve recognition

- Take two close-up images instead of one image of the entire packet.
- Make the label fill most of the frame; avoid glare, harsh reflections, motion blur and strong perspective.
- Hold the camera parallel to the package; use diffuse lighting and tap to focus.
- Use **Contrast + sharpening** if the text is faint. Use **Adaptive threshold** if the background is uneven. Thresholding can also destroy colored or very fine text, so compare results.
- Make sure all values are readable; tiny decimals and units are easy to misread.
- Try the same label under each preprocessing mode and record the results for your IPCV report.

## API overview

- `GET /api/health` — backend and PaddleOCR package status
- `GET /api/catalog` — supported nutrient and allergen lists
- `POST /api/analyze` — multipart form with `nutrition_image`, optional `ingredients_image`, and `preprocess_mode`
- `POST /api/parse` — parse corrected OCR text without running OCR again

The backend does not store uploaded images; it processes them in memory. PaddleOCR may store downloaded model weights in its local cache.

## Project structure

```text
labellens/
├── index.html
├── package.json
├── vite.config.js
├── README.md
├── src/
│   ├── App.jsx
│   ├── main.jsx
│   └── styles.css
└── backend/
    ├── __init__.py
    ├── main.py
    ├── food_parser.py
    ├── requirements.txt
    └── tests/
        └── test_food_parser.py
```

## IPCV concepts you can explain

- Image orientation correction and resizing
- Grayscale conversion and local contrast enhancement (CLAHE)
- Denoising and unsharp masking
- Adaptive thresholding
- Text detection / recognition and bounding boxes
- Row grouping and OCR confidence
- Rule-based information extraction from recognized text
- Unit conversion, plausibility checks and uncertainty handling
- Evaluation of different preprocessing variants on the same dataset

## Limitations (important for your report)

- No OCR engine can guarantee all values from every photo. If a nutrient is not printed, it should remain unavailable; if it is present but unreadable, the app can still miss it.
- A photo containing multiple numerical columns can be ambiguous. Confirm whether the printed values are per 100 g, per 100 ml, per serving, or percent reference intake.
- Nutrient aliases and allergen synonyms are rule-based; brand-specific layouts, local-language labels, handwriting, unusual ingredients and OCR errors can still defeat them.
- A unit conversion is a calculation from a recognized printed value, not independent verification.
- Ingredient-term matches can be false positives, and allergen declarations can be missed. This app cannot certify safety.

## Evaluation idea

Build a test set of 30–50 products. Manually transcribe only the information visibly present. Measure: (1) text-line recognition accuracy, (2) nutrient exact-value accuracy, (3) unit accuracy, (4) ingredient section extraction success, (5) declared-allergen recall, and (6) processing time. Compare original, contrast/sharpen, and adaptive threshold using the *same* photos. Report missing values separately from incorrect values.

## Build frontend

```bash
npm run build
```

The Python OCR models are loaded on the first analysis request. The first scan can be slower while model weights download.
