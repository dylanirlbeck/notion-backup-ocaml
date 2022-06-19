open Lwt
open Cohttp
open Cohttp_lwt_unix
open Yojson.Basic.Util

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
      export_filename = "notion_backup.zip";
      token_v2 = Sys.getenv "NOTION_TOKEN_V2";
      space_id = Sys.getenv "NOTION_SPACE_ID";
    }
end

let config = Config.create

let headers =
  let h = Header.init () in
  let h = Header.add h "content-type" "application/json" in
  Header.add h "cookie" (Printf.sprintf "token_v2=%s; " config.token_v2)

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
                  ( "exportOptions",
                    `Assoc
                      [
                        ("exportType", `String "markdown");
                        ("timeZone", `String "America/Chicago");
                        ("locale", `String "en");
                      ] );
                ] );
          ] );
    ]

let request endpoint ~params =
  let body_string = Yojson.to_string params in
  Client.post
    ~body:(Cohttp_lwt.Body.of_string body_string)
    ~headers
    (Uri.of_string (config.api ^ endpoint))
  >>= fun (_, body) ->
  body |> Cohttp_lwt.Body.to_string >|= fun body -> body

let construct_task_ids task_id : Yojson.t =
  `Assoc [ ("taskIds", `List [ `String task_id ]) ]

(* let print_tasks tasks = *)
(*   List.iter *)
(*     (fun task -> *)
(*       task |> member "id" |> to_string |> Printf.printf "Fetched task %s\n") *)
(*     tasks *)

let rec request_tasks task_id =
  Unix.sleep 2;
  let task_ids_param = construct_task_ids task_id in
  let tasks =
    Yojson.Basic.from_string
      (Lwt_main.run (request "/getTasks" ~params:task_ids_param))
    |> member "results" |> to_list
  in
  let task =
    List.find (fun task -> member "id" task |> to_string = task_id) tasks
  in
  let pages_exported =
    task |> member "status" |> member "pagesExported" |> to_int
  in
  Printf.printf "\rPages exported: %i" pages_exported;
  let state = task |> member "state" |> to_string in
  match state with "success" -> task | _ -> request_tasks task_id

(*Source: https://discuss.ocaml.org/t/how-do-i-download-a-file-with-cohttp/7105*)
(* let download (uri : Uri.t) (dest : string) = *)
(*   Client.get uri >>= fun (_, body) -> *)
(*   (1* TODO: check response for status codes, follow redirects if applicable *1) *)
(*   let stream = Cohttp_lwt.Body.to_stream body in *)
(*   Lwt_io.with_file ~mode:Lwt_io.output dest (fun chan -> *)
(*       Lwt_stream.iter_s (Lwt_io.write chan) stream) *)

let () =
  let task_id =
    Yojson.Basic.from_string
      (Lwt_main.run (request "/enqueueTask" ~params:enqueue_task_param))
    |> member "taskId" |> to_string
  in
  Printf.printf "Enqueued task %s\n" task_id;
  let ret_task = request_tasks task_id in
  let export_url =
    ret_task |> member "status" |> member "exportURL" |> to_string
  in
  Printf.printf "\nExport created, downloading: %s" export_url;
  (* let _ = download (Uri.of_string export_url) config.export_filename in *)
  let _ =
    Unix.create_process "curl"
      [| "curl"; export_url; "-o"; config.export_filename |]
      Unix.stdin Unix.stdout Unix.stderr
  in
  Printf.printf "\nDownload complete: %s" config.export_filename
