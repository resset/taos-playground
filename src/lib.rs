// Steve Operating System
// Stephen Marz
// 21 Sep 2019
#![no_std]
#![feature(panic_info_message, asm)]

// ///////////////////////////////////
// / RUST MACROS
// ///////////////////////////////////
#[macro_export]
macro_rules! print {
    ($($args:tt)+) => {{
		use core::fmt::Write;
		let _ = write!(crate::uart::Uart::new(0x1000_0000), $($args)+);
	}};
}
#[macro_export]
macro_rules! println
{
	() => ({
		print!("\r\n")
	});
	($fmt:expr) => ({
		print!(concat!($fmt, "\r\n"))
	});
	($fmt:expr, $($args:tt)+) => ({
		print!(concat!($fmt, "\r\n"), $($args)+)
	});
}

// ///////////////////////////////////
// / LANGUAGE STRUCTURES / FUNCTIONS
// ///////////////////////////////////
#[no_mangle]
extern "C" fn eh_personality() {}
#[panic_handler]
fn panic(info: &core::panic::PanicInfo) -> ! {
    print!("Aborting: ");
    if let Some(_p) = info.location() {
        println!(
            "line {}, file {}: {}",
            _p.line(),
            _p.file(),
            info.message().unwrap()
        );
    } else {
        println!("no information available.");
    }
    abort();
}
#[no_mangle]
extern "C" fn abort() -> ! {
    loop {
        unsafe {
            asm!("wfi"::::"volatile");
        }
    }
}

// ///////////////////////////////////
// / CONSTANTS
// ///////////////////////////////////

// ///////////////////////////////////
// / ENTRY POINT
// ///////////////////////////////////
#[no_mangle]
extern "C" fn kmain() {
    // Main should initialize all sub-systems and get
    // ready to start scheduling. The last thing this
	// should do is start the timer.

	// Let's try using our newly minted UART by initializing it first.
	// The UART is sitting at MMIO address 0x1000_0000, so for testing
	// now, lets connect to it and see if we can initialize it and write
	// to it.
	let mut uart = uart::Uart::new(0x1000_0000);

	uart.init();

	println!("taos v0.1");

	// Now see if we can read stuff:
	// Usually we can use #[test] modules in Rust, but it would convolute the
	// task at hand. So, we'll just add testing snippets.
	loop {
		if let Some(c) = uart.get() {
			uart.put(c);
		}
	}
}

// ///////////////////////////////////
// / RUST MODULES
// ///////////////////////////////////

pub mod uart;
