import { renderMermaid, renderMermaidAscii } from "./src/index.ts";

async function main() {
  const args = process.argv.slice(2);

  const ascii = args.includes("--ascii") || args.includes("-a");
  const help = args.includes("--help") || args.includes("-h");

  if (help) {
    console.log(`beautiful-mermaid - Render Mermaid diagrams as SVG or ASCII art

Usage:
  beautiful-mermaid [options] [file]
  cat diagram.mmd | beautiful-mermaid [options]

Options:
  -a, --ascii     Output ASCII art instead of SVG
  -h, --help      Show this help message

If no file is specified, reads from stdin.`);
    process.exit(0);
  }

  const fileArg = args.find((a: string) => !a.startsWith("-"));

  let input: string;

  if (fileArg) {
    input = await Bun.file(fileArg).text();
  } else {
    const chunks: Buffer[] = [];
    for await (const chunk of Bun.stdin.stream()) {
      chunks.push(chunk as Buffer);
    }
    input = Buffer.concat(chunks).toString("utf-8");
  }

  const trimmed = input.trim();
  if (!trimmed) {
    console.error("Error: No input provided");
    process.exit(1);
  }

  if (ascii) {
    const result = renderMermaidAscii(trimmed);
    console.log(result);
  } else {
    const result = await renderMermaid(trimmed);
    console.log(result);
  }
}

main();
