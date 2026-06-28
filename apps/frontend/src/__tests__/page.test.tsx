import { render, screen } from "@testing-library/react";
import { describe, it, expect } from "vitest";
import Page from "../../app/page";

describe("Home Page", () => {
  it("renders the main heading", () => {
    render(<Page />);
    const heading = screen.getByRole("heading", { level: 1 });
    expect(heading).toBeInTheDocument();
  });

  it("renders the Vercel logomark", () => {
    render(<Page />);
    const logo = screen.getByRole("img", { name: /Vercel logomark/i });
    expect(logo).toBeInTheDocument();
  });

  it("renders the Next.js logo", () => {
    render(<Page />);
    const logo = screen.getByRole("img", { name: /Next\.js logo/i });
    expect(logo).toBeInTheDocument();
  });

  it("has links to Learning, Templates, Deploy Now, and Documentation", () => {
    render(<Page />);
    expect(screen.getByRole("link", { name: /Templates/i })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Learning/i })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Deploy Now/i })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Documentation/i })).toBeInTheDocument();
  });
});
