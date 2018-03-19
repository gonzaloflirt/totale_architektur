(
e = ();

// SETTINGS //////////////////////////////////////////////////////////////////////////////

e.numSpeakers = 22;
e.numEinheiten = 15;
e.blockigVolume = -3;
e.fliessendVolume = 0;
e.sumsVolume = -24;
e.emptyBucketChance = [0.05, 0.95];
e.emptyBucketWaitRange = [0.01, 1.5];
e.emptySceneWait = 0.01;
e.dataDir = Document.current.dir +/+ 'data';
s.options.outDevice = 'Built-in Output';

//////////////////////////////////////////////////////////////////////////////////////////

s.options.numOutputBusChannels = e.numSpeakers;
s.options.numInputBusChannels = 0;
s.options.numBuffers = 2048;
e.buffers = ();
e.buffers.clips = ();
e.buffers.sums = ();
e.serverVolume = 0;

e.readEinheit = {{ |einheit|
	var data, clips, sums;
	data = (Document.current.dir +/+ 'database2sc.py e' + einheit).unixCmdGetStdOut;
	data = data.stripWhiteSpace.replace("\n", "").interpret;
	clips = data[0];
	sums = data[1];
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

e.emptyBucket = {{
	|einheit|
	var clips, channels, durations;
	clips = (Document.current.dir +/+ 'database2sc.py c' + einheit).unixCmdGetStdOut();
	clips = (clips.stripWhiteSpace.replace("\n", "")).interpret;
	clips = clips.scramble[0..1000];
	channels = Pxrand((0..e.numSpeakers-1), inf).asStream;
	durations = 0 ! clips.size();
	postln("empty bucket" + einheit ++ "," + clips.size() + "clips");
	clips.do {
		|path, i|
		var buffer = Buffer.read(s, path);
		var wait = exprand(e.emptyBucketWaitRange[0], e.emptyBucketWaitRange[1]);
		s.sync;
		(0..i).do { |j|
			durations[j] = durations[j] - wait;
		};
		durations[i] = buffer.duration;
		Synth(\blockig, [
			\bufnum, buffer.bufnum,
			\channel, channels.next
		]);
		{ buffer.free(); }.defer(buffer.duration + 1);
		wait.wait;
	};
	if (durations.size > 0, {
		durations.maxItem.wait;
	});
}};

e.playClips = {{
	|buffers, duration|
	buffers = buffers.scramble();
	switch (e.form.next,
		\blockig, {
			var extend = (ceil(e.numSpeakers / buffers.size()) * buffers.size()).asInt;
			var bufferIndex = (0..(buffers.size() -1)).wrapExtend(extend).scramble().foldExtend(e.numSpeakers.asInt).sort();
			var defers = Array.fill(buffers.size(), { |i|   rrand(0, duration - buffers[i].duration()) });
			bufferIndex.do({ |index, channel|
				var buffer = buffers[index];
				Synth(\blockig, [
					\bufnum, buffer.bufnum,
					\defer, defers[index],
					\channel, channel,
					\vol, e.blockigVolume
				]);
			});
		},
		\fliessend, {
			var iphase = Array.interpolation(buffers.size(), 0, 2 - (2 / buffers.size())) + rrand(0, 2);
			var panSpeed = duration.reciprocal * [-1, 1].choose;
			buffers.do({ |buffer, index|
				var defer = rrand(0, duration - buffer.duration());
				Synth(\fliessend, [
					\bufnum, buffer.bufnum,
					\defer, defer,
					\iphase, iphase[index],
					\panSpeed, panSpeed,
					\vol, e.fliessendVolume
				]);
			});
	});
}};

e.playSums = {{
	|buffers, duration|
	var channels = (0..e.numSpeakers-1).scramble;
	buffers.collect({
		|b, i|
		var defer = rrand(0, duration - b.duration());
		Synth(\blockig, [
			\bufnum, b.bufnum,
			\defer, defer,
			\channel, channels[i],
			\vol, e.sumsVolume
		]);
	});
}};

e.playEinheit = {{
	|einheit|
	e.readEinheit.value(einheit);
	s.sync;
	if (e.buffers.clips[einheit].notNil, {
		var clipsDuration = e.buffers.clips[einheit].collect({ |b| b.duration(); });
		var sumsDuration = e.buffers.sums[einheit].collect({ |b| b.duration(); });
		var duration = (clipsDuration.addAll(sumsDuration)).maxItem;
		postln("play einheit" + einheit ++ "," + "duration" + duration ++ "," + e.buffers.clips[einheit].size() + "clips");
		e.playClips.value(e.buffers.clips[einheit], duration);
		e.playSums.value(e.buffers.sums[einheit], duration);
		wait(duration);
	}, {
		postln("noop einheit " + einheit);
		e.emptySceneWait.wait;
	});
}};

s.waitForBoot{

	SynthDef(\blockig, {
		|bufnum, defer = 0, channel = 0, numChannels = 1, vol = 0, fade = 0.002|
		var env = EnvGen.kr(Env([0, 0, 1], [defer, 0]));
		var sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), trigger: env - 0.5, doneAction: 2);
		Out.ar(channel, (vol.dbamp * sig * env));
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

	e.einheit = Pseq((1..e.numEinheiten), inf).asStream;
	e.form  = Pseq([\blockig, \fliessend], inf).asStream;
	e.playSequence = Pwrand([e.emptyBucket, e.playEinheit], e.emptyBucketChance, inf).asStream;

	Tdef(\main, { loop {
		s.volume = e.serverVolume;
		e.playSequence.next.value(e.einheit.next);
	}}).play;

	OSCdef(\volume, {|msg| e.serverVolume = msg[1]; }, '/volume')
}
)

Tdef(\main).stop;

Ndef(\stereoMixdown, {
	ReplaceOut.ar(0, Splay.ar(In.ar(0, e.numSpeakers)));
	ReplaceOut.ar(2, DC.ar(0) ! (e.numSpeakers - 2));
}).play;
Ndef(\stereoMixdown).free;
