module assignment2;
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

bitstruct MoveImmReg : char
{
	uint reg : 0..2;
	bool w : 3;
	uint code : 4..7;
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

fn String name_for_rm(uint rm) @inline
{
	static String[] names = { "bx + si", "bx + di", "bp + si", "bp + di", "si", "di", "bp", "bx" };
	return names[rm];
}

fn void! decode_mov(char c, File in, File out)
{
	Move m = (Move) char[2] { c, in.getc()! };

    switch (m.mod)
    {
		case 0b00:
			if (m.rm == 0b110)
			{
				ushort offset = in.getc()! + in.getc()! << 8;
				if (m.d)
				{
					out.printfn("mov [%d], %s", offset, name_for_reg(m.reg, true));
				}
				else
				{
					out.printfn("mov %s, [%d]", name_for_reg(m.reg, true), offset);
				}
				return;
			}
			if (m.d)
			{
				out.printfn("mov %s, [%s]", name_for_reg(m.reg, m.w), name_for_rm(m.rm));
			}
			else
			{
				out.printfn("mov [%s], %s", name_for_rm(m.rm), name_for_reg(m.reg, m.w));
			}
		case 0b10:
		case 0b01:
			ushort offset = in.getc()!;
			if (m.mod == 0b10) offset += in.getc()! << 8;
			if (m.d)
			{
				out.printfn("mov %s, [%s + %d]", name_for_reg(m.reg, m.w), name_for_rm(m.rm), offset);
			}
			else
			{
				out.printfn("mov [%s + %d], %s", name_for_rm(m.rm), offset, name_for_reg(m.reg, m.w));
			}
        case 0b11:
        	uint dest = m.d ? m.reg : m.rm;
            uint source = m.d ? m.rm : m.reg;
		    out.printfn("mov %s, %s", name_for_reg(dest, m.w), name_for_reg(source, m.w));
		default:
			unreachable();
    }
}

fn void! decode_mov_imm_reg(char c, File in, File out)
{
	MoveImmReg instr = (MoveImmReg)c;
	char lo = in.getc()!;
	char hi = instr.w ? in.getc()! : 0;
	out.printfn("mov %s, %d", name_for_reg(instr.reg, instr.w), lo + hi * 256U);
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
		char! c = f.getc();
		if (catch c) break;
		switch (c)
		{
			case 0b10001000..0b10001011:
				decode_mov(c, f, out)!;
			case 0b10110000..0b10111111:
				decode_mov_imm_reg(c, f, out)!;
			default:
				unreachable("Unexpected instruction in stream");
		}
	}
	io::printn("All read ok");
}
