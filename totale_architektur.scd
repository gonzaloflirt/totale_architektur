(
e = ();

// SETTINGS //////////////////////////////////////////////////////////////////////////////

e.numSpeakers = 9;
e.numEinheiten = 15;
e.dataDir = Document.current.dir +/+ 'data';
s.options.outDevice = 'Built-in Output';

//////////////////////////////////////////////////////////////////////////////////////////

s.options.numOutputBusChannels = e.numSpeakers;
s.options.numInputBusChannels = 0;
e.buffers = ();
e.einheit = Pseq((0..e.numEinheiten), inf).asStream;
e.form  = Pseq([\blockig, \fliessend], inf).asStream;

e.readEinheit = {{ |einheit|
	var paths = (Document.current.dir +/+ 'einheit2sc.py' + einheit).unixCmdGetStdOut.interpret;
	if (e.buffers[einheit].notNil, {
		e.buffers[einheit].collect({|buffer| buffer.free()});
	});
	if (paths.size() > 0,
		{
			e.buffers[einheit] = paths.collect({|path| Buffer.read(s, path) });
		}, {
			e.buffers[einheit] = nil;
	});
}};

e.playEinheit = {{
	|buffers|
	var form = e.form.next;
	var maxDuration = (buffers.collect({ |b| b.duration(); })).maxItem;
	var channel = round(Array.interpolation(buffers.size(), 0, e.numSpeakers - 1));
	var iphase = Array.interpolation(buffers.size(), 0, 2 - (2 / buffers.size())) + rrand(0, 2);
	var panSpeed = maxDuration.reciprocal;
	if (buffers.size == 1, { channel = [rrand(0, e.numSpeakers - 1)]; });
	buffers.scramble.collect({
		|b, i|
		var defer = rrand(0, maxDuration - b.duration());
		Synth.new(form, [
			\bufnum, b.bufnum,
			\defer, defer,
			\channel, channel[i],
			\iphase, iphase[i],
			\panSpeed, panSpeed
		]);
	});
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

	s.sync;
	s.meter;

	Tdef(\play, { loop {
		var einheit = e.einheit.next;
		e.readEinheit.value(einheit);
		s.sync;
		if (e.buffers[einheit].notNil, {
			var duration = (e.buffers[einheit].collect({ |b| b.duration(); })).maxItem;
			postln("play einheit " + einheit + " with duration " + duration);
			e.playEinheit.value(e.buffers[einheit]);
			wait(duration + 1);
		}, {
			postln("noop einheit " +  einheit);
			0.01.wait;
		});
	}}).play;
}
)