using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace randevu_app_api.Migrations
{
    /// <inheritdoc />
    public partial class _31050034 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "Şifre",
                table: "Adminler",
                newName: "Sifre");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "Sifre",
                table: "Adminler",
                newName: "Şifre");
        }
    }
}
