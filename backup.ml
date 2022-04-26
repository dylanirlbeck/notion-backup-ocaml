open Lwt
open Cohttp
open Cohttp_lwt_unix

(* Notion API configuration: API url, export filename, Notion token v2, Notion
    space ID.

    TODO Do some smart constructing.
*)
module Config = struct
  type t = {
    api : string;
    export_filename : string;
    token_v2 : string;
    space_id : string;
  }

  let create =
    {
      api = "https://www.notion.so/api/v3";
      export_filename = "export.zip";
      token_v2 = Sys.getenv "NOTION_TOKEN_V2";
      space_id = Sys.getenv "NOTION_SPACE_ID";
    }
end

let config = Config.create

let headers =
  let h = Header.init () in
  let h = Header.add h "content-type" "application/json" in
  Header.add h "cookie" (Printf.sprintf "token_v2 = %s; " config.token_v2)

let enqueue_task_param : Yojson.t =
  `Assoc
    [
      ( "task",
        `Assoc
          [
            ("eventName", `String "exportSpace");
            ( "request",
              `Assoc
                [
                  ("spaceId", `String config.space_id);
                  ( "exportType",
                    `Assoc
                      [
                        ("exportType", `String "markdown");
                        ("timeZone", `String "Europe/Amsterdam");
                        ("locale", `String "en");
                      ] );
                ] );
          ] );
    ]

let request endpoint ~params =
  Yojson.pretty_to_channel stdout params;
  let body_string = Yojson.to_string params in
  Client.post
    ~body:(Cohttp_lwt.Body.of_string body_string)
    ~headers
    (Uri.of_string (config.api ^ endpoint))
  >>= fun (resp, body) ->
  body |> Cohttp_lwt.Body.to_string >|= fun body ->
  let code = resp |> Response.status |> Code.code_of_status in
  Printf.printf "Response code: %d\n" code;
  Printf.printf "Headers: %s\n" (resp |> Response.headers |> Header.to_string);
  body

let () =
  let body = Lwt_main.run (request "enqueueTask" ~params:enqueue_task_param) in
  print_endline ("Received body\n" ^ body)
