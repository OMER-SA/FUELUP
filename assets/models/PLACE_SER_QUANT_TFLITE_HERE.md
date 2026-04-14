# Model Required
Download SER_quant.tflite from:
https://github.com/Hannibal0420/Speech-Emotion-Recognition-TinyML

Place it at: assets/models/SER_quant.tflite

Model details:
- Size: 150KB (int8 quantized)
- Input: MFCC features [1, timesteps, 40]
- Output: 6 emotion classes
- Classes (in order): angry, calm, fearful, happy, neutral, sad
- Sample rate: 16000 Hz, mono channel
- Inference time: ~300ms on mobile
