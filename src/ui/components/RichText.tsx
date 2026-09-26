/// Rich text renderer — replaces the `gpt_markdown` widget from the Flutter
/// app (port of `lib/core/widgets/rich_markdown.dart`). Renders the subset of
/// GFM the backend actually emits: headings, bold/italic, inline code, lists,
/// links (as styled text), and blockquote lines. `widget:` fences are stripped
/// so native-card instructions never leak into the conversation.

import React, { useMemo } from "react";
import { Text, View, StyleSheet, Linking, TextStyle } from "react-native";

import { AppColors } from "../appColors";

interface RichTextProps {
  content: string;
  baseColor?: string;
}

interface Block {
  kind: "heading" | "paragraph" | "list" | "quote" | "table";
  lines: string[];
  level?: number;
}

function parseBlocks(source: string): Block[] {
  const blocks: Block[] = [];
  const lines = source.replace(/```[\s\S]*?```/g, "").split("\n");
  let current: Block | null = null;
  for (const raw of lines) {
    const line = raw.replace(/\s+$/, "");
    const heading = /^(#{1,6})\s+(.*)$/.exec(line);
    const bullet = /^\s*[-*•]\s+(.*)$/.exec(line);
    const quote = /^\s*>\s?(.*)$/.exec(line);
    if (heading !== null) {
      current = { kind: "heading", lines: [heading[2]], level: heading[1].length };
      blocks.push(current);
      continue;
    }
    if (bullet !== null) {
      if (current?.kind === "list") current.lines.push(bullet[1]);
      else {
        current = { kind: "list", lines: [bullet[1]] };
        blocks.push(current);
      }
      continue;
    }
    if (quote !== null) {
      if (current?.kind === "quote") current.lines.push(quote[1]);
      else {
        current = { kind: "quote", lines: [quote[1]] };
        blocks.push(current);
      }
      continue;
    }
    if (line.trim() === "") {
      current = null;
      continue;
    }
    if (current?.kind === "paragraph") current.lines.push(line);
    else {
      current = { kind: "paragraph", lines: [line] };
      blocks.push(current);
    }
  }
  return blocks;
}

function renderInline(text: string, keyPrefix: string, baseStyle: TextStyle): React.ReactNode[] {
  // Bold, italic, inline code, links.
  const pattern = /(\*\*[^*]+\*\*|__[^_]+__|\*[^*]+\*|`[^`]+`|\[[^\]]+\]\([^)]+\))/g;
  const nodes: React.ReactNode[] = [];
  let last = 0;
  let match: RegExpExecArray | null;
  let index = 0;
  while ((match = pattern.exec(text)) !== null) {
    if (match.index > last) nodes.push(text.slice(last, match.index));
    const token = match[0];
    const key = `${keyPrefix}-${index++}`;
    if (token.startsWith("**") || token.startsWith("__")) {
      nodes.push(<Text key={key} style={[baseStyle, { fontWeight: "700", color: AppColors.textPrimary }]}>{token.slice(2, -2)}</Text>);
    } else if (token.startsWith("`")) {
      nodes.push(<Text key={key} style={[baseStyle, styles.code]}>{token.slice(1, -1)}</Text>);
    } else if (token.startsWith("*")) {
      nodes.push(<Text key={key} style={[baseStyle, { fontStyle: "italic" }]}>{token.slice(1, -1)}</Text>);
    } else {
      const link = /\[([^\]]+)\]\(([^)]+)\)/.exec(token)!;
      nodes.push(
        <Text key={key} style={[baseStyle, styles.link]} onPress={() => void Linking.openURL(link[2])}>
          {link[1]}
        </Text>,
      );
    }
    last = match.index + token.length;
  }
  if (last < text.length) nodes.push(text.slice(last));
  return nodes;
}

export function RichText({ content, baseColor = AppColors.textPrimary }: RichTextProps): React.ReactElement {
  const blocks = useMemo(() => parseBlocks(content), [content]);
  const bodyStyle = { color: baseColor };
  return (
    <View style={styles.root}>
      {blocks.map((block, i) => {
        if (block.kind === "heading") {
          const size = block.level !== undefined ? Math.max(15, 24 - (block.level - 1) * 2) : 18;
          return (
            <Text key={i} style={[styles.heading, { fontSize: size }]}>
              {renderInline(block.lines[0] ?? "", `h${i}`, styles.heading)}
            </Text>
          );
        }
        if (block.kind === "list") {
          return (
            <View key={i} style={styles.list}>
              {block.lines.map((line, j) => (
                <Text key={j} style={[styles.body, bodyStyle]}>
                  {"•  "}
                  {renderInline(line, `l${i}-${j}`, styles.body)}
                </Text>
              ))}
            </View>
          );
        }
        if (block.kind === "quote") {
          return (
            <View key={i} style={styles.quote}>
              {block.lines.map((line, j) => (
                <Text key={j} style={[styles.quoteText]}>
                  {renderInline(line, `q${i}-${j}`, styles.quoteText)}
                </Text>
              ))}
            </View>
          );
        }
        return (
          <Text key={i} style={[styles.body, bodyStyle]}>
            {block.lines.map((line, j) => (
              <Text key={j}>
                {line}
                {j < block.lines.length - 1 ? " " : ""}
              </Text>
            ))}
          </Text>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    gap: 10,
  },
  heading: {
    color: AppColors.textPrimary,
    fontWeight: "700",
  },
  body: {
    color: AppColors.textPrimary,
    fontSize: 14.5,
    lineHeight: 22,
  },
  list: {
    gap: 6,
    paddingLeft: 4,
  },
  quote: {
    borderLeftWidth: 3,
    borderLeftColor: AppColors.accent,
    paddingLeft: 10,
    gap: 4,
  },
  quoteText: {
    color: AppColors.textSecondary,
    fontSize: 13.5,
    lineHeight: 20,
    fontStyle: "italic",
  },
  code: {
    fontFamily: "monospace",
    fontSize: 13,
    color: AppColors.accentSoft,
    backgroundColor: AppColors.glassFillStrong,
  },
  link: {
    color: AppColors.sky,
    textDecorationLine: "underline",
  },
});
