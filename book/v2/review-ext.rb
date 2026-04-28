# generate with gemini
# -*- coding: utf-8 -*-
module ReVIEW
  class Compiler
    # コンパイラのエラーを防ぐおまじない
    definline :color
  end

  module ColorizeLatexHook
    # 通常の文章中で @<color> が使われた場合の処理
    def inline_color(str)
      color, text = str.split(',', 2).map(&:strip)
      return text unless color && text
      "\\textcolor{#{color}}{#{text}}"
    end

    # 最終的なLaTeX出力テキスト全体に対する一括置換
    def result
      res = super
      
      # 1. LaTeXコマンドを無効化するバリア (reviewverb環境) を完全に除去する
      # （これによりTechBooster本来の alltt 環境が活き、コマンドが実行可能になります）
      res.gsub!(/\\begin\{reviewverb\}\r?\n?/, "")
      res.gsub!(/\\end\{reviewverb\}\r?\n?/, "")
      
      # 2. コードブロック内でエスケープされた @<color>{色, 文字} を \textcolor に置換
      res.gsub!(/@(?:\\textless\{\}|<)color(?:\\textgreater\{\}|>)(?:\\\{|\{)([^,]+),\s*(.*?)(?:\\\}|\})/) do
        "\\textcolor{#{$1}}{#{$2}}"
      end
      
      res # 最後に必ず置換結果を返す
    end
  end

  class LATEXBuilder
    prepend ColorizeLatexHook
  end

  # HTML出力用
  module ColorizeHtmlHook
    def inline_color(str)
      color, text = str.split(',', 2).map(&:strip)
      return text unless color && text
      %(<span style="color:#{color}">#{text}</span>)
    end

    def result
      res = super
      res.gsub!(/@(?:&lt;|<)color(?:&gt;|>)\{([^,]+),\s*(.*?)\}/) do
        %(<span style="color:#{$1}">#{$2}</span>)
      end
      res
    end
  end

  class HTMLBuilder
    prepend ColorizeHtmlHook
  end
end
