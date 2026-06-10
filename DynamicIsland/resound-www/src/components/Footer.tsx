export default function Footer() {
  return (
    <footer className="border-t border-border py-8 px-6">
      <div className="max-w-6xl mx-auto flex flex-col md:flex-row items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <img src="/logo.svg" alt="Resound" className="w-6 h-6" />
          <span className="text-sm text-text-muted">
            Built by <span className="text-text-secondary">Evans Elabo</span>
          </span>
        </div>

        <div className="flex items-center gap-6">
          <a
            href="https://github.com/ellaboevans/resound-dynamic-island"
            target="_blank"
            rel="noopener noreferrer"
            className="text-sm text-text-muted hover:text-text-secondary transition-colors"
          >
            GitHub
          </a>
          <a
            href="#faq"
            className="text-sm text-text-muted hover:text-text-secondary transition-colors"
          >
            FAQ
          </a>
          <span className="text-xs text-text-muted">
            &copy; {new Date().getFullYear()}
          </span>
        </div>
      </div>
    </footer>
  );
}
