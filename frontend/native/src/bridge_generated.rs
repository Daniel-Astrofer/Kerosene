// AUTO-GENERATED bridge scaffolding for flutter_rust_bridge 1.82.x
// Rust side: forwards Dart port calls to the api module.
// NOTE: The actual C ABI exports (sync_start_tor_client, free_rust_string)
//       live in api.rs. This file only provides the async FRB wrapper
//       and the global handler required by the FRB runtime.

#[allow(unused)]
use super::api::*;
use flutter_rust_bridge::*;

// ── Async wire wrapper (called via Dart isolate port) ──────────────────────
// This is separate from the `sync_start_tor_client` C export in api.rs.
pub fn wire_start_tor_client_impl(port_: MessagePort) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "start_tor_client",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || move |_task_callback| start_tor_client(),
    )
}

/// Required by the FRB runtime: delivers output from Dart closures back into Rust.
#[no_mangle]
pub extern "C" fn dart_fn_deliver_output(
    _call_id: i32,
    _ptr_: *mut u8,
    _rust_vec_len_: i32,
    _data_len_: i32,
) {
    // Handled internally by flutter_rust_bridge.
}

// Global FRB handler — required by the macros used in bridge_generated.io.rs.
flutter_rust_bridge::support::lazy_static! {
    pub static ref FLUTTER_RUST_BRIDGE_HANDLER: support::DefaultHandler =
        support::DefaultHandler::default();
}
