module assignment3738;
import std::io;
bitstruct Move : char[2]
{
	bool w : 0;
	bool d : 1;
	uint code : 2..7;
	uint rm : 8..10;
	uint reg : 11..13;
	uint mod : 14..15;
}

fn String name_for_reg(uint reg, bool w)
{
	static String[] names = {
		"al", "ax",
		"cl", "cx",
		"dl", "dx",
		"bl", "bx",
		"ah", "sp",
		"ch", "bp",
		"dh", "si",
		"bh", "di"
	};
	return names[reg * 2 + (uint)w];
}

fn void! main(String[] args)
{
	if (args.len != 3)
	{
		io::printn("Expected two arguments, input and output");
		return;
	}
	File f = file::open(args[1], "rb")!;
	defer (void)f.close();
	File out = file::open(args[2], "wb")!;
	defer (void)out.close();
	out.printn("bits 16")!;
	out.printn()!;
	while (!f.eof())
	{
		char[2] buffer;
		usz read = f.read(&buffer)!;
		if (!read) break;
		assert(read == 2, "Unexpected size");
		Move m = (Move)buffer;
		assert(m.code == 0b100010, "Unexpected instruction");
		out.printfn("mov %s, %s", name_for_reg(m.rm, m.w), name_for_reg(m.reg, m.w));
	}
	io::printn("All read ok");
}
