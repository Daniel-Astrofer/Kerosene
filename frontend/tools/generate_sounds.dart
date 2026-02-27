import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  final outDir = Directory('../assets/sounds');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  // Generate Sounds
  _createWav('${outDir.path}/login.wav', _generateLoginSound());
  _createWav('${outDir.path}/ghost_on.wav', _generateGhostOnSound());
  _createWav('${outDir.path}/ghost_off.wav', _generateGhostOffSound());
  _createWav('${outDir.path}/transaction.wav', _generateTransactionSound());
  _createWav('${outDir.path}/error.wav', _generateErrorSound());

  // ignore: avoid_print
  print('✅ Cybercore sounds generated successfully in assets/sounds/');
}

const int sampleRate = 44100;

void _createWav(String path, List<double> samples) {
  final file = File(path);
  final byteData = ByteData(44 + samples.length * 2);

  // RIFF header
  byteData.setUint32(0, 0x52494646, Endian.big); // "RIFF"
  byteData.setUint32(4, 36 + samples.length * 2, Endian.little);
  byteData.setUint32(8, 0x57415645, Endian.big); // "WAVE"

  // fmt subchunk
  byteData.setUint32(12, 0x666D7420, Endian.big); // "fmt "
  byteData.setUint32(16, 16, Endian.little); // Subchunk1Size
  byteData.setUint16(20, 1, Endian.little); // AudioFormat (PCM)
  byteData.setUint16(22, 1, Endian.little); // NumChannels (Mono)
  byteData.setUint32(24, sampleRate, Endian.little); // SampleRate
  byteData.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
  byteData.setUint16(32, 2, Endian.little); // BlockAlign
  byteData.setUint16(34, 16, Endian.little); // BitsPerSample 16-bit

  // data subchunk
  byteData.setUint32(36, 0x64617461, Endian.big); // "data"
  byteData.setUint32(40, samples.length * 2, Endian.little);

  for (int i = 0; i < samples.length; i++) {
    // Convert -1.0 to 1.0 -> Int16
    int pcm = (samples[i] * 32767).round().clamp(-32768, 32767);
    byteData.setInt16(44 + i * 2, pcm, Endian.little);
  }

  file.writeAsBytesSync(byteData.buffer.asUint8List());
}

// ==========================================
// SYNTHESIS ALGORITHMS
// ==========================================

// Helper: Sine wave generator
double _sine(double t, double freq) => sin(2 * pi * freq * t);

// Helper: Square wave
double _square(double t, double freq) =>
    sin(2 * pi * freq * t) >= 0 ? 1.0 : -1.0;

// Helper: Sawtooth wave
double _saw(double t, double freq) => 2 * (t * freq - (t * freq + 0.5).floor());

// Helper: Envelope
double _adsr(
  double t,
  double attack,
  double decay,
  double sustain,
  double release,
  double totalDuration,
) {
  if (t < attack) {
    return t / attack;
  }
  if (t < attack + decay) {
    return 1.0 - ((t - attack) / decay) * (1.0 - sustain);
  }
  if (t < totalDuration - release) {
    return sustain;
  }
  if (t < totalDuration) {
    return sustain * (1.0 - (t - (totalDuration - release)) / release);
  }
  return 0.0;
}

List<double> _generateLoginSound() {
  final duration = 0.6;
  final samples = <double>[];
  for (int i = 0; i < duration * sampleRate; i++) {
    double t = i / sampleRate;
    // Fast arpeggio logic
    double freq;
    if (t < 0.15) {
      freq = 880; // A5
    } else if (t < 0.3) {
      freq = 1108; // C#6
    } else if (t < 0.45) {
      freq = 1318; // E6
    } else {
      freq = 1760; // A6
    }

    // Add some "hacker" modulation
    double wave = _square(t, freq) * 0.5 + _sine(t, freq * 1.01) * 0.5;
    double env = _adsr(t, 0.01, 0.05, 0.7, 0.1, duration);
    samples.add(wave * env * 0.4); // Volume 0.4
  }
  return samples;
}

List<double> _generateGhostOnSound() {
  final duration = 0.8;
  final samples = <double>[];
  for (int i = 0; i < duration * sampleRate; i++) {
    double t = i / sampleRate;
    // Deep bass drop / wub
    double freq = 150 * exp(-3 * t); // Exponential slide down
    double wave = _saw(t, freq);

    // Low pass filter simulator (simple moving average logic approximated by softening edges)
    // Add sub-bass sine
    wave = (wave * 0.4) + (_sine(t, freq / 2) * 0.6);

    double env = _adsr(t, 0.05, 0.2, 0.6, 0.4, duration);
    samples.add(wave * env * 0.6);
  }
  return samples;
}

List<double> _generateGhostOffSound() {
  final duration = 0.4;
  final samples = <double>[];
  for (int i = 0; i < duration * sampleRate; i++) {
    double t = i / sampleRate;
    // Fast high pitch chirp down
    double freq = 1000 - (t * 2000);
    if (freq < 100) {
      freq = 100;
    }

    double wave = _sine(t, freq) * 0.7 + _square(t, freq * 1.5) * 0.3;
    double env = _adsr(t, 0.01, 0.05, 0.4, 0.1, duration);
    samples.add(wave * env * 0.5);
  }
  return samples;
}

List<double> _generateTransactionSound() {
  final duration = 0.7;
  final samples = <double>[];
  for (int i = 0; i < duration * sampleRate; i++) {
    double t = i / sampleRate;
    // Cyber-coin: two pure high sines overlapping with a bright fast delay
    double wave =
        _sine(t, 2000) * _adsr(t, 0.01, 0.1, 0, 0, duration) +
        _sine(t, 3000) * _adsr(t - 0.1, 0.01, 0.2, 0, 0, duration) +
        _sine(t, 4000) * _adsr(t - 0.2, 0.01, 0.4, 0, 0, duration);
    samples.add(wave * 0.3);
  }
  return samples;
}

List<double> _generateErrorSound() {
  final duration = 0.5;
  final samples = <double>[];
  final rand = Random();
  for (int i = 0; i < duration * sampleRate; i++) {
    double t = i / sampleRate;
    // Harsh static glitch buzz
    double baseFreq = 120 + (rand.nextDouble() * 20); // jitter
    double wave = _square(t, baseFreq);

    // Amplitude modulation to make it "stutter"
    double mod = _square(t, 15) > 0 ? 1 : 0.2;

    double env = _adsr(t, 0.01, 0.1, 0.8, 0.1, duration);
    samples.add(wave * env * mod * 0.5);
  }
  return samples;
}
