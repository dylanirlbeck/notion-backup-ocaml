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
;;

print_endline config.token_v2

let body =
  Client.get (Uri.of_string config.api) >>= fun (resp, body) ->
  let code = resp |> Response.status |> Code.code_of_status in
  Printf.printf "Response code: %d\n" code;
  Printf.printf "Headers: %s\n" (resp |> Response.headers |> Header.to_string);
  body |> Cohttp_lwt.Body.to_string >|= fun body ->
  Printf.printf "Body of length: %d\n" (String.length body);
  body

let () =
  let body = Lwt_main.run body in
  print_endline ("Received body\n" ^ body)
