import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { App } from "../src/App";

describe("frontend app", () => {
  it("renders main title", () => {
    render(<App />);
    expect(screen.getByText(/Serverless App Template - Hello World/i)).toBeInTheDocument();
  });
});
