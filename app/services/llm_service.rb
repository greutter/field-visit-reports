class LlmService
  class TranscriptionError < StandardError; end
  class ReportGenerationError < StandardError; end

  class << self
    def transcribe_audio(audio_message)
      return nil unless audio_message.audio_file.attached?

      # Download the audio file to a temp file
      audio_file = audio_message.audio_file
      temp_file = download_to_tempfile(audio_file)

      begin
        transcription = openai_transcribe(temp_file, audio_file.content_type)
        transcription
      ensure
        temp_file.close
        temp_file.unlink
      end
    end

    def generate_field_report(field_visit, transcription)
      field = field_visit.field

      prompt = build_report_prompt(field_visit, field, transcription)

      response = openai_chat_completion(prompt)
      response
    end

    private

    def download_to_tempfile(audio_file)
      extension = case audio_file.content_type
      when "audio/webm" then ".webm"
      when "audio/mp4", "audio/m4a" then ".m4a"
      when "audio/mpeg" then ".mp3"
      else ".audio"
      end

      temp_file = Tempfile.new([ "audio", extension ])
      temp_file.binmode
      temp_file.write(audio_file.download)
      temp_file.rewind
      temp_file
    end

    def openai_transcribe(temp_file, content_type)
      require "net/http"
      require "uri"

      api_key = Rails.application.credentials.dig(:openai, :api_key) || ENV["OPENAI_API_KEY"]

      unless api_key.present?
        Rails.logger.warn("OpenAI API key not configured, using placeholder transcription")
        return "[Transcription placeholder - Configure OPENAI_API_KEY to enable actual transcription]"
      end

      uri = URI("https://api.openai.com/v1/audio/transcriptions")

      boundary = "----RubyFormBoundary#{SecureRandom.hex(8)}"

      body = build_multipart_body(temp_file, boundary)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?
      http.read_timeout = 120

      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{api_key}"
      request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
      request.body = body

      response = http.request(request)

      if response.code.to_i == 200
        JSON.parse(response.body)["text"]
      else
        error_message = JSON.parse(response.body)["error"]["message"] rescue response.body
        raise TranscriptionError, "OpenAI transcription failed: #{error_message}"
      end
    end

    def build_multipart_body(temp_file, boundary)
      # Use binary encoding for the body to handle audio data
      body = "".b

      # File field
      body << "--#{boundary}\r\n".b
      body << "Content-Disposition: form-data; name=\"file\"; filename=\"audio#{File.extname(temp_file.path)}\"\r\n".b
      body << "Content-Type: application/octet-stream\r\n\r\n".b
      body << temp_file.read
      body << "\r\n".b

      # Model field
      body << "--#{boundary}\r\n".b
      body << "Content-Disposition: form-data; name=\"model\"\r\n\r\n".b
      body << "whisper-1\r\n".b

      # Language field (Spanish for agrochemical context)
      body << "--#{boundary}\r\n".b
      body << "Content-Disposition: form-data; name=\"language\"\r\n\r\n".b
      body << "es\r\n".b

      # Prompt field to provide context and avoid hallucinations
      body << "--#{boundary}\r\n".b
      body << "Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".b
      body << "Transcripcion de audio de visita a campo agricola. El experto describe observaciones sobre cultivos, plagas, enfermedades, condiciones del suelo y recomendaciones de tratamiento.\r\n".b

      body << "--#{boundary}--\r\n".b
      body
    end

    def openai_chat_completion(prompt)
      require "net/http"
      require "uri"

      api_key = Rails.application.credentials.dig(:openai, :api_key) || ENV["OPENAI_API_KEY"]

      unless api_key.present?
        Rails.logger.warn("OpenAI API key not configured, using placeholder report")
        return generate_placeholder_report
      end

      uri = URI("https://api.openai.com/v1/chat/completions")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?
      http.read_timeout = 120

      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{api_key}"
      request["Content-Type"] = "application/json"

      request.body = {
        model: "gpt-4o",
        messages: [
          {
            role: "system",
            content: system_prompt
          },
          {
            role: "user",
            content: prompt
          }
        ],
        temperature: 0.7,
        max_tokens: 2000
      }.to_json

      response = http.request(request)

      if response.code.to_i == 200
        JSON.parse(response.body)["choices"][0]["message"]["content"]
      else
        error_message = JSON.parse(response.body)["error"]["message"] rescue response.body
        raise ReportGenerationError, "OpenAI report generation failed: #{error_message}"
      end
    end

    def system_prompt
      <<~PROMPT
        You are an expert agronomist assistant helping to create professional field visit reports.
        Your task is to analyze field visit observations and audio transcriptions from agrochemical experts
        and generate comprehensive, well-structured field visit reports.

        The reports should be in Spanish and include:
        - Executive summary
        - Field conditions observed
        - Pest/disease observations
        - Recommendations for treatment
        - Product application suggestions if mentioned
        - Follow-up actions required

        Be professional, technical, and actionable in your recommendations.
      PROMPT
    end

    def build_report_prompt(field_visit, field, transcription)
      <<~PROMPT
        Generate a comprehensive field visit report based on the following information:

        **Field Information:**
        - Field Name: #{field.name}
        - Location: #{field.location}
        - Crop Type: #{field.crop_type}
        - Area: #{field.area_hectares || 'Not specified'} hectares
        - Field Notes: #{field.notes || 'None'}

        **Visit Information:**
        - Date: #{field_visit.created_at.strftime("%B %d, %Y")}

        **Audio Transcriptions from Field Expert:**
        #{transcription}

        Please generate a professional field visit report in Spanish with the following sections:
        1. Resumen Ejecutivo
        2. Condiciones del Campo
        3. Observaciones de Plagas/Enfermedades
        4. Recomendaciones de Tratamiento
        5. Productos Sugeridos (si se mencionan)
        6. Acciones de Seguimiento
      PROMPT
    end

    def generate_placeholder_report
      <<~REPORT
        ## Resumen Ejecutivo
        [Este es un reporte de ejemplo. Configure la API key de OpenAI para generar reportes reales.]

        ## Condiciones del Campo
        - Las condiciones del campo fueron evaluadas durante la visita.
        - Se requiere análisis adicional de las transcripciones de audio.

        ## Observaciones
        - Las observaciones detalladas están disponibles en las transcripciones de audio.

        ## Recomendaciones
        - Configure OPENAI_API_KEY para obtener recomendaciones basadas en IA.
        - Revise las transcripciones de audio para más detalles.

        ## Acciones de Seguimiento
        - Programar visita de seguimiento según sea necesario.
      REPORT
    end
  end
end
