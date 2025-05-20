class PCMPlayerProcessor extends AudioWorkletProcessor {
    constructor() {
      super();
      this.buffer = new Int16Array(0);
      this.port.onmessage = (event) => {
        const chunk = new Int16Array(event.data);
        const combined = new Int16Array(this.buffer.length + chunk.length);
        combined.set(this.buffer);
        combined.set(chunk, this.buffer.length);
        this.buffer = combined;
      };
    }
  
    process(inputs, outputs) {
      const output = outputs[0];
  
      if (this.buffer.length < 128) {
        // não há dados suficientes
        return true;
      }
  
      for (let channel = 0; channel < output.length; channel++) {
        const outputChannel = output[channel];
  
        for (let i = 0; i < outputChannel.length; i++) {
          const sample = this.buffer[i];
          outputChannel[i] = sample / 32768; // PCM 16-bit para float [-1, 1]
        }
      }
  
      this.buffer = this.buffer.slice(128); // remove o que já tocou
      return true;
    }
  }
  
  registerProcessor('pcm-player', PCMPlayerProcessor);
  