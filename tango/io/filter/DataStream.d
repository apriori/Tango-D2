/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Oct 2007

        author:         Kris

*******************************************************************************/

module tango.io.filter.DataStream;

private import tango.io.Buffer;

private import tango.io.Conduit;

private import tango.core.ByteSwap;

/*******************************************************************************

*******************************************************************************/

class DataInput : InputFilter, Buffered
{       
        private bool    flip;
        private final IBuffer input;

        /***********************************************************************

                Propagate ctor to superclass

        ***********************************************************************/

        this (InputStream stream, bool flip = false)
        {
                this.flip = flip;
                auto b = cast(Buffered) stream;
                input = (b ? b.buffer : new Buffer (stream.conduit));
                super (input);
        }

        /***********************************************************************
        
                Buffered interface

        ***********************************************************************/

        final IBuffer buffer ()
        {
                return input;
        }

        /***********************************************************************

                Write to conduit from a source array. The provided src
                content will be written to the conduit.

                Returns the number of bytes written from src, which may
                be less than the quantity provided

        ***********************************************************************/

        override uint read (void[] dst)
        {
                return input.read (dst);
        }

        /***********************************************************************

        ***********************************************************************/

        final bool readBool ()
        {
                bool x;
                input.readExact (&x, x.sizeof);
                return x;
        }

        /***********************************************************************

        ***********************************************************************/

        final byte readByte ()
        {
                byte x;
                input.readExact (&x, x.sizeof);
                return x;
        }

        /***********************************************************************

        ***********************************************************************/

        final short readShort ()
        {
                short x;
                input.readExact (&x, x.sizeof);
                if (flip)
                    ByteSwap.swap16(&x, x.sizeof);
                return x;
        }

        /***********************************************************************

        ***********************************************************************/

        final int readInt ()
        {
                int x;
                input.readExact (&x, x.sizeof);
                if (flip)
                    ByteSwap.swap16(&x, x.sizeof);
                return x;
        }

        /***********************************************************************

        ***********************************************************************/

        final long readLong ()
        {
                long x;
                input.readExact (&x, x.sizeof);
                if (flip)
                    ByteSwap.swap16(&x, x.sizeof);
                return x;
        }

        /***********************************************************************

        ***********************************************************************/

        final float readFloat ()
        {
                float x;
                input.readExact (&x, x.sizeof);
                if (flip)
                    ByteSwap.swap16(&x, x.sizeof);
                return x;
        }

        /***********************************************************************

        ***********************************************************************/

        final double readDouble ()
        {
                double x;
                input.readExact (&x, x.sizeof);
                if (flip)
                    ByteSwap.swap16(&x, x.sizeof);
                return x;
        }

}


/*******************************************************************************

*******************************************************************************/

class DataOutput : OutputFilter, Buffered
{       
        private bool    flip;
        private final IBuffer output;

        /***********************************************************************

                Propagate ctor to superclass

        ***********************************************************************/

        this (OutputStream stream, bool flip = false)
        {
                this.flip = flip;
                auto b = cast(Buffered) stream;
                output = (b ? b.buffer : new Buffer (stream.conduit));
                super (output);
        }

        /***********************************************************************
        
                Buffered interface

        ***********************************************************************/

        final IBuffer buffer ()
        {
                return output;
        }

        /***********************************************************************

                Write to conduit from a source array. The provided src
                content will be written to the conduit.

                Returns the number of bytes written from src, which may
                be less than the quantity provided

        ***********************************************************************/

        override uint write (void[] src)
        {
                output.append (src);
                return src.length;
        }

        /***********************************************************************

        ***********************************************************************/

        final void writeBool (bool x)
        {
                output.append (&x, x.sizeof);
        }

        /***********************************************************************

        ***********************************************************************/

        final void writeByte (byte x)
        {
                output.append (&x, x.sizeof);
        }

        /***********************************************************************

        ***********************************************************************/

        final void writeShort (short x)
        {
                if (flip)
                    ByteSwap.swap16 (&x, x.sizeof);
                output.append (&x, x.sizeof);
        }

        /***********************************************************************

        ***********************************************************************/

        final void writeInt (int x)
        {
                if (flip)
                    ByteSwap.swap32 (&x, x.sizeof);
                output.append (&x, uint.sizeof);
        }

        /***********************************************************************

        ***********************************************************************/

        final void writeLong (long x)
        {
                if (flip)
                    ByteSwap.swap64 (&x, x.sizeof);
                output.append (&x, x.sizeof);
        }

        /***********************************************************************

        ***********************************************************************/

        final void writeFloat (float x)
        {
                if (flip)
                    ByteSwap.swap32 (&x, x.sizeof);
                output.append (&x, x.sizeof);
        }

        /***********************************************************************

        ***********************************************************************/

        final void writeDouble (double x)
        {
                if (flip)
                    ByteSwap.swap64 (&x, x.sizeof);
                output.append (&x, x.sizeof);
        }
}

/*******************************************************************************

*******************************************************************************/

debug (UnitTest)
{
        import tango.io.Buffer;

        unittest
        {
                auto buf = new Buffer(32);

                auto output = new DataOutput (buf);
                output.write ("blah blah");
                output.writeInt (1024);

                auto input = new DataInput (buf);
                assert (input.read(new char[9]) is 9);
                assert (input.readInt is 1024);
        }
}