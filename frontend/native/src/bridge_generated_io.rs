// IO-layer generated scaffolding for flutter_rust_bridge 1.82.x
// Exposes the async `wire_start_tor_client` C symbol that Dart's FRB runtime
// calls when the client uses the non-sync path.
// The SYNC path is handled by `sync_start_tor_client` in api.rs.

use super::bridge_generated::*;
use flutter_rust_bridge::support;

// ── wire functions ──────────────────────────────────────────────────────────

#[no_mangle]
pub extern "C" fn wire_start_tor_client(port_: i64) {
    wire_start_tor_client_impl(port_)
}

// ── allocate / related / Wire2Api sections intentionally empty ──────────────

// ── impl NewWithNullPtr ─────────────────────────────────────────────────────

pub trait NewWithNullPtr {
    fn new_with_null_ptr() -> Self;
}

impl<T> NewWithNullPtr for *mut T {
    fn new_with_null_ptr() -> Self {
        std::ptr::null_mut()
    }
}

// ── sync execution mode utility ─────────────────────────────────────────────

#[no_mangle]
pub extern "C" fn free_WireSyncReturn(ptr: support::WireSyncReturn) {
    unsafe {
        let _ = support::box_from_leak_ptr(ptr);
    };
}
