using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace randevu_app_api.Migrations
{
    /// <inheritdoc />
    public partial class _31050015 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "Onay",
                table: "Dukkanlar",
                type: "bit",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Onay",
                table: "Dukkanlar");
        }
    }
}
