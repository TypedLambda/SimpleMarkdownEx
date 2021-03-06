defprotocol SimpleMarkdown.Renderer.HTML do
    @moduledoc """
      A renderer protocol for HTML.

      Individual rule renderers can be overriden or new ones may be
      added. Rule types follow the format of structs defined under
      `SimpleMarkdown.Attributes`. e.g. If there is a rule with the
      name `:header`, to provide a rendering implementation for that
      rule, you would specify `for: SimpleMarkdown.Attribute.Header`.

      Rules then consist of a Map with an `input` field, and an optional
      `option` field. See <code class="inline"><a href="SimpleMarkdown.html#t:SimpleMarkdown.attribute/0"><span class="hljs-constant">SimpleMarkdown.</span>attribute</a></code>.

      Example
      -------
        defimpl SimpleMarkdown.Renderer.HTML, for: SimpleMarkdown.Attribute.Header do
            def render(%{ input: input, option: size }), do: "<h\#{size}>\#{SimpleMarkdown.Renderer.HTML.render(input)}</h\#{size}>"
        end
    """

    @doc """
      Render the parsed markdown as HTML.
    """
    @spec render(Stream.t | [SimpleMarkdown.attribute | String.t] | SimpleMarkdown.attribute | String.t) :: String.t
    def render(ast)
end

defimpl SimpleMarkdown.Renderer.HTML, for: [List, Stream] do
    def render(ast) do
        Enum.reduce(ast, "", fn attribute, string ->
            string <> SimpleMarkdown.Renderer.HTML.render(attribute)
        end)
    end
end

defimpl SimpleMarkdown.Renderer.HTML, for: BitString do
    def render(string), do: string
end

defimpl SimpleMarkdown.Renderer.HTML, for: SimpleMarkdown.Attribute.LineBreak do
    def render(_), do: "<br>"
end

defimpl SimpleMarkdown.Renderer.HTML, for: SimpleMarkdown.Attribute.Header do
    def render(%{ input: input, option: size }), do: "<h#{size}>#{SimpleMarkdown.Renderer.HTML.render(input)}</h#{size}>"
end

defimpl SimpleMarkdown.Renderer.HTML, for: SimpleMarkdown.Attribute.Emphasis do
    def render(%{ input: input, option: :regular }), do: "<em>#{SimpleMarkdown.Renderer.HTML.render(input)}</em>"
    def render(%{ input: input, option: :strong }), do: "<strong>#{SimpleMarkdown.Renderer.HTML.render(input)}</strong>"
end

defimpl SimpleMarkdown.Renderer.HTML, for: SimpleMarkdown.Attribute.HorizontalRule do
    def render(_), do: "<hr>"
end

defimpl SimpleMarkdown.Renderer.HTML, for: SimpleMarkdown.Attribute.Table do
    def render(%{ input: input, option: heading = [{_, _}|_] }) do
        { titles, aligns } = Enum.unzip(heading)

        input = Enum.map(input, fn
            %{ __struct__: SimpleMarkdown.Attribute.Row, input: elements } -> %{ __struct__: SimpleMarkdown.Attribute.Row, input: elements, option: aligns }
        end)

        "<table><thead><tr>#{Enum.reduce(titles, "", &(&2 <> "<th>#{SimpleMarkdown.Renderer.HTML.render(&1)}</th>"))}</tr></thead><tbody>#{SimpleMarkdown.Renderer.HTML.render(input)}</tbody></table>"
    end
    def render(%{ input: input, option: aligns }) do
        input = Enum.map(input, fn
            %{ __struct__: SimpleMarkdown.Attribute.Row, input: elements } -> %{ __struct__: SimpleMarkdown.Attribute.Row, input: elements, option: aligns }
        end)

        "<table><tbody>#{SimpleMarkdown.Renderer.HTML.render(input)}</tbody></table>"
    end
end

defimpl SimpleMarkdown.Renderer.HTML, for: SimpleMarkdown.Attribute.Row do
    def render(%{ input: input, option: align }) do
        "<tr>" <> (Enum.zip(input, align) |> Enum.reduce("", fn
            { input, :default }, acc -> acc <> "<td>#{SimpleMarkdown.Renderer.HTML.render(input)}</td>"
            { input, align }, acc -> acc <> "<td style=\"text-align: #{to_string(align)};\">#{SimpleMarkdown.Renderer.HTML.render(input)}</td>"
        end)) <> "</tr>"
    end
    def render(%{ input: input }), do: "<tr>#{Enum.reduce(input, "", &(&2 <> "<td>#{SimpleMarkdown.Renderer.HTML.render(&1)}</td>"))}</tr>"
end

defimpl SimpleMarkdown.Renderer.HTML, for: SimpleMarkdown.Attribute.TaskList do
    def render(%{ input: input }), do: "<ul>#{SimpleMarkdown.Renderer.HTML.render(input)}</ul>"
end

defimpl SimpleMarkdown.Renderer.HTML, for: SimpleMarkdown.Attribute.Task do
    def render(%{ input: input, option: :deselected }), do: "<li><input type=\"checkbox\" disabled>#{SimpleMarkdown.Renderer.HTML.render(input)}</li>"
    def render(%{ input: input, option: :selected }), do: "<li><input type=\"checkbox\" checked disabled>#{SimpleMarkdown.Renderer.HTML.render(input)}</li>"
end

defimpl SimpleMarkdown.Renderer.HTML, for: SimpleMarkdown.Attribute.List do
    def render(%{ input: input, option: :unordered }), do: "<ul>#{SimpleMarkdown.Renderer.HTML.render(input)}</ul>"
    def render(%{ input: input, option: :ordered }), do: "<ol>#{SimpleMarkdown.Renderer.HTML.render(input)}</ol>"
end

defimpl SimpleMarkdown.Renderer.HTML, for: SimpleMarkdown.Attribute.Item do
    def render(%{ input: input }), do: "<li>#{SimpleMarkdown.Renderer.HTML.render(input)}</li>"
end

defimpl SimpleMarkdown.Renderer.HTML, for: SimpleMarkdown.Attribute.PreformattedCode do
    def render(%{ input: input, option: syntax }) do
        module = SimpleMarkdown.child_module(SimpleMarkdown.Attribute.PreformattedCode, syntax)
        try do
            Protocol.assert_impl!(SimpleMarkdown.Renderer.HTML, module)
        rescue
            ArgumentError -> SimpleMarkdown.Renderer.HTML.render(%{ __struct__: SimpleMarkdown.Attribute.PreformattedCode, input: input })
        else
            :ok -> SimpleMarkdown.Renderer.HTML.render(%{ __struct__: module, input: input })
        end
    end

    def render(%{ input: input }), do: "<pre><code>#{SimpleMarkdown.Renderer.HTML.render(input) |> HtmlEntities.encode}</code></pre>"
end

defimpl SimpleMarkdown.Renderer.HTML, for: SimpleMarkdown.Attribute.Paragraph do
    def render(%{ input: input }), do: "<p>#{SimpleMarkdown.Renderer.HTML.render(input)}</p>"
end

defimpl SimpleMarkdown.Renderer.HTML, for: SimpleMarkdown.Attribute.Blockquote do
    def render(%{ input: input }), do: "<blockquote>#{SimpleMarkdown.Renderer.HTML.render(input)}</blockquote>"
end

defimpl SimpleMarkdown.Renderer.HTML, for: SimpleMarkdown.Attribute.Link do
    def render(%{ input: input, option: url }), do: "<a href=\"#{url}\">#{SimpleMarkdown.Renderer.HTML.render(input)}</a>"
end

defimpl SimpleMarkdown.Renderer.HTML, for: SimpleMarkdown.Attribute.Image do
    def render(%{ input: input, option: url }), do: "<img src=\"#{url}\" alt=\"#{SimpleMarkdown.Renderer.HTML.render(input)}\">"
end

defimpl SimpleMarkdown.Renderer.HTML, for: SimpleMarkdown.Attribute.Code do
    def render(%{ input: input }), do: "<code>#{SimpleMarkdown.Renderer.HTML.render(input) |> HtmlEntities.encode}</code>"
end
