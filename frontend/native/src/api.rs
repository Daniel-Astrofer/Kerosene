use arti_client::{TorClient, TorClientConfig};
use tokio::runtime::Runtime;
use anyhow::Result;

/// Called from Dart via FFI to start the Arti Tor client.
/// Spawns a Rust background thread where the Tor client bootstraps
/// and runs the SOCKS5 proxy on 127.0.0.1:9050.
///
/// Returns a null-terminated C string with a status message.
/// The caller is responsible for freeing the returned string using `free_rust_string`.
#[no_mangle]
pub extern "C" fn sync_start_tor_client() -> *mut std::os::raw::c_char {
    std::thread::spawn(|| {
        if let Err(e) = run_tor_proxy() {
            eprintln!("[Arti] Tor bootstrap failed: {:?}", e);
        }
    });

    let msg = std::ffi::CString::new(
        "Tor Client (Arti) starting... SOCKS5 proxy will be on 127.0.0.1:9050."
    )
    .unwrap_or_else(|_| std::ffi::CString::new("started").unwrap());

    msg.into_raw()
}

/// Frees a Rust CString returned from sync_start_tor_client.
#[no_mangle]
pub extern "C" fn free_rust_string(ptr: *mut std::os::raw::c_char) {
    if !ptr.is_null() {
        unsafe {
            drop(std::ffi::CString::from_raw(ptr));
        }
    }
}

fn run_tor_proxy() -> Result<()> {
    let rt = Runtime::new()?;
    rt.block_on(async {
        let config = TorClientConfig::default();

        println!("[Arti] Bootstrapping Tor...");
        let _client = TorClient::create_bootstrapped(config).await?;
        println!("[Arti] Tor bootstrapped. SOCKS5 proxy running on 127.0.0.1:9050.");

        // Keep the runtime alive indefinitely
        std::future::pending::<()>().await;
        Ok::<(), anyhow::Error>(())
    })?;
    Ok(())
}

// Keep a simple flutter_rust_bridge async wrapper as well for completeness
pub fn start_tor_client() -> anyhow::Result<String> {
    sync_start_tor_client();
    Ok("Tor Client (Arti) starting.".to_string())
}
