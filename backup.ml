open Lwt
open Cohttp
open Cohttp_lwt_unix

(* Notion API configuration: API url, export filename, Notion token v2, Notion
    space ID.

    TODO Do some smart constructing.
*)
type config = {
  api : string;
  export_filename : string;
  token_v2 : string;
  space_id : string;
}

let config =
  {
    api = "https://www.notion.so/api/v3";
    export_filename = "export.zip";
    token_v2 = Sys.getenv "NOTION_TOKEN_V2";
    space_id = Sys.getenv "NOTION_SPACE_ID";
  }

let headers =
  let h = Header.init () in
  let h = Header.add h "content-type" "application/json" in
  Header.add h "cookie" (Printf.sprintf "token_v2 = %s; " config.token_v2)

let enqueue_task_param =
  {|
  {"task" : {
    "eventName": "exportSpace",
    "request": {
      "spaceId": config.space_id
    }
  }}
|}
;;

print_endline enqueue_task_param

let request endpoint ~params =
  Printf.printf "Params: %d\n" params;
  Client.get ~headers (Uri.of_string (config.api ^ endpoint))
  >>= fun (_, body) ->
  body |> Cohttp_lwt.Body.to_string >|= fun body ->
  (*
    let code = resp |> Response.status |> Code.code_of_status in
    Printf.printf "Response code: %d\n" code;
    Printf.printf "Headers: %s\n" (resp |> Response.headers |>
    Header.to_string);
  *)
  body

let () =
  let body = Lwt_main.run (request "enqueueTask" ~params:0) in
  print_endline ("Received body\n" ^ body)
