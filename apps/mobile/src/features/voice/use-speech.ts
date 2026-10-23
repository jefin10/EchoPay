import { ExpoSpeechRecognitionModule, useSpeechRecognitionEvent } from 'expo-speech-recognition';
import { useRef, useState } from 'react';

/**
 * On-device speech-to-text. Streams interim transcripts while listening and
 * calls `onFinal` once with the final transcript.
 */
export function useSpeech(onFinal: (text: string) => void) {
  const [listening, setListening] = useState(false);
  const [transcript, setTranscript] = useState('');
  const [error, setError] = useState<string | null>(null);
  const finalSent = useRef(false);

  useSpeechRecognitionEvent('start', () => setListening(true));
  useSpeechRecognitionEvent('end', () => setListening(false));
  useSpeechRecognitionEvent('result', (event) => {
    const text = event.results[0]?.transcript ?? '';
    setTranscript(text);
    if (event.isFinal && text.trim() && !finalSent.current) {
      finalSent.current = true;
      onFinal(text.trim());
    }
  });
  useSpeechRecognitionEvent('error', (event) => {
    setListening(false);
    // "no-speech" and "aborted" are normal outcomes, not failures worth shouting about.
    if (event.error === 'no-speech' || event.error === 'speech-timeout') setError("Didn't catch that. Try again.");
    else if (event.error !== 'aborted') setError(event.message || 'Speech recognition failed.');
  });

  const start = async () => {
    setError(null);
    setTranscript('');
    finalSent.current = false;
    const { granted } = await ExpoSpeechRecognitionModule.requestPermissionsAsync();
    if (!granted) {
      setError('Microphone permission is needed for voice commands.');
      return;
    }
    ExpoSpeechRecognitionModule.start({ lang: 'en-IN', interimResults: true, continuous: false });
  };

  const stop = () => ExpoSpeechRecognitionModule.stop();

  return { listening, transcript, error, start, stop, setTranscript };
}
