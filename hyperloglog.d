import std.algorithm;
import std.math;

//Implementation from this paper
//http://stefanheule.com/papers/edbt13-hyperloglog.pdf

alias ulong function(string) HashFunc;

//Hash function is djb2
ulong djb2(string text){
	ulong hash = 5381;
	return reduce!((a,b) => ((a << 5) + a) + b)(hash, text);
}

private double[] Aggregate(string[]words, int countregisters, int p, HashFunc hashfunc){
	//init registers
	double[] registers = new double[](countregisters);
	for(int i = 0;i < countregisters;++i)registers[i] = 0;
	double v = 1.04/0.32;
	int shift = 32 - cast(int)ceil(log2(v*v));
	for(int i = 0;i < words.length;++i){
		ulong hash = hashfunc(words[i]);
		uint idx = cast(uint)hash >>> shift;
		registers[idx] = max(registers[idx], maxzones(hash, shift));
	}
	return registers;
}

private double Estimation(double alpha, double m, double[] registers){
	double register_result = 1/map!(x => pow(2,-x))(registers).sum();
	double empty_registers = filter!(x => x == 0)(registers).sum();
	double E = alpha * pow(m, 2) * register_result;
	double dexp32 =  pow(2,32);
	if(E < 5/2 * m){
		if(empty_registers != 0)
			return LinerCounting(m, empty_registers);
		else
			return E;
	}
	else if (E <= 1/30 * dexp32){
		return E;
	}
	return -dexp32 * log(1 - E/dexp32);
}

private double maxzones(ulong hash, ulong maxvalue){
	int r = 1;
	while((hash & 1) == 0 && r <= maxvalue){
		r += 1;
		hash >>>=1;
	}
	return r;
}


double LinerCounting(double m, double numzeros){
	return m * log(m/numzeros);
}

auto HyperLogLog(int p, string[] words)in{

	assert(p >= 4 && p <= 16);
	assert(words.length > 0);

	}body {
		HashFunc hashfunc= &djb2;
		return new class {

			void addHashFunc(ulong function(string) func){
				hashfunc = func;
			}
			double compute(){
				int m = pow(2,p);
				double alpha = 0.7213/(1 + 1.079/m);
				if(m == 16) alpha = 0.673;
				if(m == 32) alpha = 0.697;
				if(m == 64) alpha = 0.709;
				//double std = 1.04/sqrt(pow(2,p));
				double [] registers = Aggregate(words, m, p, hashfunc);
				double estimated = Estimation(alpha, m, registers);
				return estimated;
			}
		};
}
