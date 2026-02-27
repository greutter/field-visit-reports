# AgroField - Field Visit Reports

A Rails 8 application for agrochemical experts to record audio observations during field visits and generate AI-powered summary reports.

## Features

- **User Authentication**: Built-in Rails 8 authentication with email/password
- **Field Management**: Create and manage agricultural fields with crop types, locations, and areas
- **Field Visits**: Track visits to fields with weather conditions and observations
- **Audio Recording**: Record audio messages directly from your mobile device's microphone
- **AI Transcription**: Automatic transcription of audio messages using OpenAI Whisper
- **Report Generation**: AI-generated comprehensive field visit reports using GPT-4
- **Mobile-First Design**: PWA-ready, optimized for field use on mobile devices
- **Spanish Language Support**: Reports generated in Spanish for Latin American agricultural context

## Requirements

- Ruby 3.2+
- Rails 8.0+
- SQLite3 (default) or PostgreSQL
- Node.js (for asset compilation)
- OpenAI API key (for transcription and report generation)

## Setup

1. **Clone the repository**
   ```bash
   cd field_visit_reports
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Configure OpenAI API Key**
   
   Using Rails credentials (recommended):
   ```bash
   bin/rails credentials:edit
   ```
   Add:
   ```yaml
   openai:
     api_key: your_openai_api_key_here
   ```
   
   Or using environment variable:
   ```bash
   export OPENAI_API_KEY=your_openai_api_key_here
   ```

4. **Setup the database**
   ```bash
   bin/rails db:setup
   ```
   This creates the database, runs migrations, and seeds demo data.

5. **Start the development server**
   ```bash
   bin/dev
   ```
   This starts both Rails and Tailwind CSS watcher.

6. **Access the application**
   - Open http://localhost:3000
   - Demo credentials: `demo@agrofield.com` / `password123`

## Usage

### Creating Fields
1. Navigate to "Fields" from the dashboard
2. Click "Add Field" and enter field details (name, location, crop type, area)

### Recording Field Visits
1. Select a field and click "New Visit"
2. Enter visit details (date, weather, temperature)
3. Use the record button to capture audio observations
4. Record multiple audio messages during your visit

### Generating Reports
1. After recording your observations, click "Generate Report"
2. The system will:
   - Transcribe all audio messages using OpenAI Whisper
   - Generate a comprehensive report using GPT-4
3. View and print the final report

## Architecture

### Models
- `User`: Authentication and field ownership
- `Field`: Agricultural field information
- `FieldVisit`: Individual visit records with status tracking
- `AudioMessage`: Audio recordings with transcriptions

### Key Components
- **Audio Recorder**: Stimulus controller for mobile microphone recording
- **LLM Service**: OpenAI integration for transcription and report generation
- **Background Jobs**: Solid Queue for async transcription and report generation

### Technologies
- Rails 8.0 with Hotwire (Turbo + Stimulus)
- Tailwind CSS 4.0
- Active Storage for audio file storage
- Solid Queue for background jobs
- OpenAI API (Whisper + GPT-4)

## Testing

```bash
bin/rails test
bin/rails test:system
```

## Deployment

The application is configured for deployment with Kamal. See `config/deploy.yml` for configuration.

```bash
kamal setup
kamal deploy
```

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `OPENAI_API_KEY` | OpenAI API key for transcription/reports | Yes (for AI features) |
| `SECRET_KEY_BASE` | Rails secret key | Yes (production) |
| `DATABASE_URL` | Database connection URL | No (uses SQLite by default) |

## License

MIT License
