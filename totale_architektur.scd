(
e = ();

// SETTINGS //////////////////////////////////////////////////////////////////////////////

e.numSpeakers = 5;
e.numEinheiten = 15;
e.sumsVolume = -3;
e.dataDir = Document.current.dir +/+ 'data';
s.options.outDevice = 'Built-in Output';

//////////////////////////////////////////////////////////////////////////////////////////

s.options.numOutputBusChannels = e.numSpeakers;
s.options.numInputBusChannels = 0;
e.buffers = ();
e.buffers.clips = ();
e.buffers.sums = ();
e.einheit = Pseq((1..e.numEinheiten), inf).asStream;
e.form  = Pseq([\blockig, \fliessend], inf).asStream;

e.readEinheit = {{ |einheit|
	var data = (Document.current.dir +/+ 'einheit2sc.py' + einheit).unixCmdGetStdOut.interpret;
	var clips = data[0];
	var sums = data[1];
	if (e.buffers.clips[einheit].notNil, {
		e.buffers.clips[einheit].collect({|buffer| buffer.free()});
	});
	if (e.buffers.sums[einheit].notNil, {
		e.buffers.sums[einheit].collect({|buffer| buffer.free()});
	});
	if (clips.size() > 0,
		{
			e.buffers.clips[einheit] = clips.collect({|path| Buffer.read(s, path) });
		}, {
			e.buffers.clips[einheit] = nil;
	});
	if (sums.size() > 0,
		{
			e.buffers.sums[einheit] = sums.collect({|path| Buffer.read(s, path) });
		}, {
			e.buffers.sums[einheit] = nil;
	});
}};

e.playClips = {{
	|buffers, duration|
	var form = e.form.next;
	var channel = round(Array.interpolation(buffers.size(), 0, e.numSpeakers - 1));
	var iphase = Array.interpolation(buffers.size(), 0, 2 - (2 / buffers.size())) + rrand(0, 2);
	var panSpeed = duration.reciprocal;
	if (buffers.size == 1, { channel = [rrand(0, e.numSpeakers - 1)]; });
	buffers.scramble.collect({
		|b, i|
		var defer = rrand(0, duration - b.duration());
		Synth.new(form, [
			\bufnum, b.bufnum,
			\defer, defer,
			\channel, channel[i],
			\iphase, iphase[i],
			\panSpeed, panSpeed
		]);
	});
}};

e.playSums = {{
	|buffers, duration|
	var channels = (0..e.numSpeakers-1).scramble;
	buffers.collect({
		|b, i|
		var defer = rrand(0, duration - b.duration());
		Synth.new(\blockig, [
			\bufnum, b.bufnum,
			\defer, defer,
			\channel, channels[i],
			\vol, e.sumsVolume
		]);
	});
}};

e.playEinheit = {{
	|einheit, duration|
	e.playClips.value(e.buffers.clips[einheit], duration);
	e.playSums.value(e.buffers.sums[einheit], duration);
}};

s.waitForBoot{

	SynthDef(\blockig, {
		|bufnum, defer = 0, channel = 0, vol = 0, fade = 0.002|
		var env = EnvGen.kr(Env([0, 0, 1], [defer, 0]));
		var sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), trigger: env - 0.5, doneAction: 2);
		Out.ar(channel, vol.dbamp * sig * env);
	}).add;

	SynthDef(\fliessend, {
		|bufnum, defer = 0, iphase = 0, vol = 0, panSpeed = 0.1, fade = 0.002|
		var env = EnvGen.kr(Env([0, 0, 1], [defer, 0]));
		var sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), trigger: env - 0.5, doneAction: 2);
		var pos = LFSaw.ar(panSpeed, iphase);
		sig = PanAz.ar(e.numSpeakers, vol.dbamp * env * sig, pos);
		Out.ar(0, sig);
	}).add;

	SynthDef(\limiter, {
		|level = 1, dur = 0.1|
		var sig = In.ar(0, e.numSpeakers);
		ReplaceOut.ar(0, Limiter.ar(sig, level, dur));
	}).add;

	s.sync;
	s.meter;

	Synth(\limiter);

	Tdef(\play, { loop {
		var einheit = e.einheit.next;
		e.readEinheit.value(einheit);
		s.sync;
		if (e.buffers.clips[einheit].notNil, {
			var clipsDuration = e.buffers.clips[einheit].collect({ |b| b.duration(); });
			var sumsDuration = e.buffers.sums[einheit].collect({ |b| b.duration(); });
			var duration = (clipsDuration.addAll(sumsDuration)).maxItem;
			postln("play einheit " + einheit + " with duration " + duration);
			e.playEinheit.value(einheit, duration);
			wait(duration + 1);
		}, {
			postln("noop einheit " + einheit);
			0.001.wait;
		});
	}}).play;

	OSCdef(\volume, {|msg| s.volume = msg[1]; }, '/volume')
}
)

Tdef(\play).stop;

Ndef(\stereoMixdown, {
	ReplaceOut.ar(0, Splay.ar(In.ar(0, e.numSpeakers)));
	ReplaceOut.ar(2, DC.ar(0) ! (e.numSpeakers - 2));
}).play;
Ndef(\stereoMixdown).free;