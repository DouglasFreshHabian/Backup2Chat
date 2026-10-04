group_by(.address // "Unknown")[] |

"<div class=\"conversation\" data-number=\"" + (.[0].address // "Unknown") + "\" style=\"display:none\">" +

"<h2>Conversation with " + (.[0].address // "Unknown") + "</h2>" +

"<div class=\"chat\">" +

(
  map(
    "<div class=\"" +
    (if .type=="1" then "msg received" else "msg sent" end) +
    "\">" +

    "<span class=\"time\">" +
    (.date|tonumber/1000|strftime("%Y-%m-%d %H:%M")) +
    "</span>" +

    "<p>" +
    (
      (.body // "[No Text]")
      | tostring
      | gsub("&";"&amp;")
      | gsub("<";"&lt;")
      | gsub(">";"&gt;")
    ) +
    "</p></div>"
  )
  | join("")
)

+

"</div></div>"
