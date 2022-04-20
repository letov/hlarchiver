# hlarchiver

Swift terminal archiver with Hufman and LZW algorithms.<br>

<b>USAGE</b>: archiver &lt;action&gt; &lt;in-file-path&gt; &lt;out-file-path&gt; [--block-size &lt;block-size&gt;] [--algo &lt;algo&gt;]

<b>ARGUMENTS</b>:<br>
&ensp;&lt;action&gt;                Archiver action: <b>c</b>(ompress), <b>d</b>(ecompress).<br>
&ensp;&lt;in-file-path&gt;          Input file path.<br>
&ensp;&lt;out-file-path&gt;         Output file path.<br>

<b>OPTIONS</b>:<br>
&ensp;-b, --block-size &lt;block-size&gt;<br>
&ensp;&ensp;Size of data block for compression. (default: 1000000)<br>
&ensp;-a, --algo &lt;algo&gt;       Compress algorithm: <b>h</b>(uffman), <b>l</b>(zw). (default: h)<br>
&ensp;-h, --help              Show help information.<br>
